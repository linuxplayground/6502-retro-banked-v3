	.include "lib.inc"
	.include "sdcard.inc"
        ; .include "io.inc"

	.export sector_buffer, sector_buffer_end, sector_lba

SD_CS           = %00010000
SD_SCK          = %00001000
SD_MOSI         = %00000100
SD_MISO         = %00000010

PORTA_OUTPUTPINS =  SD_CS | SD_SCK | SD_MOSI

.macro deselect
        lda     #(SD_CS|SD_MOSI)        ; deselect sdcard
        sta     via_porta
.endmacro

	.bss
cmd_idx = sdcard_param
cmd_arg = sdcard_param + 1
cmd_crc = sdcard_param + 5

sector_buffer:
	.res 512
sector_buffer_end:

sdcard_param:
	.res 1
sector_lba:
	.res 4 ; dword (part of sdcard_param) - LBA of sector to read/write
	.res 1

timeout_cnt:       .byte 0

        .code

;-----------------------------------------------------------------------------
; wait ready
;
; clobbers: A,X,Y
;-----------------------------------------------------------------------------
wait_ready:
	jsr spi_read
	cmp #$ff
	beq wait_ready

@done:	sec
	rts

; read a byte over SPI - result in A
spi_read:
        ldx     #$fe
@loop:
        lda     #SD_MOSI
        sta     via_porta
        lda     #SD_MOSI | SD_SCK
        sta     via_porta
        lda     via_porta
        and     #SD_MISO
        clc
        beq     @bitnotset
        sec
@bitnotset:
        txa
        rol
        tax
        bcs     @loop
        rts

; write a byte (A) via SPI
spi_write:
        phx
        phy
        ldx     #8
@loop:
        asl
        tay
        lda     #0
        bcc     @sendbit
        ora     #SD_MOSI
@sendbit:
        sta     via_porta
        eor     #SD_SCK
        sta     via_porta
        tya
        dex
        bne     @loop
        ply
        plx
        rts

;-----------------------------------------------------------------------------
; send_cmd - Send cmdbuf
;
; first byte of result in A, clobbers: Y
;-----------------------------------------------------------------------------
send_cmd:
	; Send the 6 cmdbuf bytes
	lda cmd_idx
	jsr spi_write
	lda cmd_arg + 3
	jsr spi_write
	lda cmd_arg + 2
	jsr spi_write
	lda cmd_arg + 1
	jsr spi_write
	lda cmd_arg + 0
	jsr spi_write
	lda cmd_crc
	jsr spi_write

	; Wait for response
	ldy #(10 + 1)
@1:	dey
	beq @error	; Out of retries
	jsr spi_read
	cmp #$ff
	beq @1

	; Success
	sec
	rts

@error:	; Error
	clc
	rts

;-----------------------------------------------------------------------------
; send_cmd_inline - send command with specified argument
;-----------------------------------------------------------------------------
.macro send_cmd_inline cmd, arg
	lda #(cmd | $40)
	sta cmd_idx

.if .hibyte(.hiword(arg)) = 0
	stz cmd_arg + 3
.else
	lda #(.hibyte(.hiword(arg)))
	sta cmd_arg + 3
.endif

.if ^arg = 0
	stz cmd_arg + 2
.else
	lda #^arg
	sta cmd_arg + 2
.endif

.if >arg = 0
	stz cmd_arg + 1
.else
	lda #>arg
	sta cmd_arg + 1
.endif

.if <arg = 0
	stz cmd_arg + 0
.else
	lda #<arg
	sta cmd_arg + 0
.endif

.if cmd = 0
	lda #$95
.else
.if cmd = 8
	lda #$87
.else
	lda #1
.endif
.endif
	sta cmd_crc
	jsr send_cmd
.endmacro

sdcmd_start:
        pha
        php
        lda     #SD_MOSI
        sta     via_porta
        jsr     sdcmd_nothingbyte
        jsr     sdcmd_nothingbyte
        lda     #$ff
        jsr     spi_write
        plp
        pla
        rts

sdcmd_nothingbyte:
        pha
        ldx     #8
@loop:
        lda     #(SD_MOSI|SD_CS)
        sta     via_porta
        lda     #(SD_SCK|SD_MOSI|SD_CS)
        sta     via_porta
        dex
        bne     @loop
        pla
        rts

sdcmd_end:
        pha
        php
        lda     #$ff
        jsr     spi_write
        jsr     sdcmd_nothingbyte
        jsr     sdcmd_nothingbyte
        lda     #(SD_CS|SD_MOSI)
        sta     via_porta
        plp
        pla
        rts

;-----------------------------------------------------------------------------
; sdcard_init
; result: C=0 -> error, C=1 -> success
;-----------------------------------------------------------------------------
sdcard_init:
        lda     #0
        sta     via_porta
        lda     #PORTA_OUTPUTPINS
        sta     via_ddra

        lda     #(SD_CS|SD_MOSI)        ; toggle clock 160 times
        ldx     #160
@clockloop:
        eor     #SD_SCK
        sta     via_porta
        dex
        bne     @clockloop

	; Enter idle state
	jsr sdcmd_start
	send_cmd_inline 0, 0
	jsr sdcmd_end
	bcs @2
	jmp @error
@2:
	cmp #1	; In idle state?
	beq @3
	jmp @error
@3:
	; SDv2? (SDHC/SDXC)
	jsr sdcmd_start
	send_cmd_inline 8, $1AA
	jsr sdcmd_end
	bcs @4
	jmp @error
@4:
	cmp #1	; No error?
	beq @5
	jmp @error
@5:
@sdv2:	; Receive remaining 4 bytes of R7 response
	jsr spi_read
	jsr spi_read
	jsr spi_read
	jsr spi_read

	; Wait for card to leave idle state
@6:	jsr sdcmd_start
	send_cmd_inline 55, 0
	jsr sdcmd_end
	bcs @7
	bra @error
@7:
	jsr sdcmd_start
	send_cmd_inline 41, $40000000
	jsr sdcmd_end
	bcs @8
	bra @error
@8:
	cmp #0
	bne @6

	; ; Check CCS bit in OCR register
	jsr sdcmd_start
	send_cmd_inline 58, 0
	jsr sdcmd_end
	cmp #0
	jsr spi_read
	and #$40	; Check if this card supports block addressing mode
	beq @error
	jsr spi_read
	jsr spi_read
	jsr spi_read

	; Success
	sec
	rts

@error:	

	; Error
	clc
	rts

;-----------------------------------------------------------------------------
; sdcard_read_sector
; Set sector_lba prior to calling this function.
; result: C=0 -> error, C=1 -> success
;-----------------------------------------------------------------------------
sdcard_read_sector:
	; Send READ_SINGLE_BLOCK command
	lda #($40 | 17)
	sta cmd_idx
	lda #1
	sta cmd_crc
	jsr send_cmd

	; Wait for start of data packet
	ldx #0
@1:	ldy #0
@2:	jsr spi_read
	cmp #$FE
	beq @start
	dey
	bne @2
	dex
	bne @1

	; Timeout error
	deselect
	clc
	rts

@start:	; Read 512 bytes of sector data
	ldx #$FF
	ldy #0
@3:	jsr spi_read
	sta sector_buffer + 0, y
	iny
	bne @3

	; Y already 0 at this point
@5:	jsr spi_read
	sta sector_buffer + 256, y
	iny
	bne @5

	; Read CRC bytes
	jsr spi_read
	jsr spi_read

	; Success
	deselect
	sec
	rts

;-----------------------------------------------------------------------------
; sdcard_write_sector
; Set sector_lba prior to calling this function.
; result: C=0 -> error, C=1 -> success
;-----------------------------------------------------------------------------
sdcard_write_sector:
	; Send WRITE_BLOCK command
	lda #($40 | 24)
	sta cmd_idx
	lda #1
	sta cmd_crc
	jsr send_cmd
	cmp #00
	bne @error

	; Wait for card to be ready
	jsr wait_ready
	bcc @error

	; Send start of data token
	lda #$FE
	jsr spi_write


	; Send 512 bytes of sector data
	ldy #0
@1:	lda sector_buffer, y		; 4
	jsr spi_write
	iny				; 2
	bne @1				; 2 + 1

	; Y already 0 at this point
@2:	lda sector_buffer + 256, y	; 4
	jsr spi_write
	iny				; 2
	bne @2				; 2 + 1

	; Dummy CRC
	lda #0
	jsr spi_write
	jsr spi_write

	; Success
	deselect
	sec
	rts

@error:	; Error
	deselect
	clc
	rts

;-----------------------------------------------------------------------------
; sdcard_check_alive
;
; Check whether the current SD card is still present, or whether it has been
; removed or replaced with a different card.
;
; Out:  c  =1: SD card is alive
;          =0: SD card has been removed, or replaced with a different card
;
; The SEND_STATUS command (CMD13) sends 16 error bits:
;  byte 0: 7  always 0
;          6  parameter error
;          5  address error
;          4  erase sequence error
;          3  com crc error
;          2  illegal command
;          1  erase reset
;          0  in idle state
;  byte 1: 7  out of range | csd overwrite
;          6  erase param
;          5  wp violation
;          4  card ecc failed
;          3  CC error
;          2  error
;          1  wp erase skip | lock/unlock cmd failed
;          0  Card is locked
; Under normal circumstances, all 16 bits should be zero.
; This command is not legal before the SD card has been initialized.
; Tests on several cards have shown that this gets respected in practice;
; the test cards all returned $1F, $FF if sent before CMD0.
; So we use CMD13 to detect whether we are still talking to the same SD
; card, or a new card has been attached.
;-----------------------------------------------------------------------------
sdcard_check_alive:
	; save sector
	jsr sdcmd_start
	ldx #0
@1:	lda sector_lba, x
	pha
	inx
	cpx #4
	bne @1

	send_cmd_inline 13, 0 ; CMD13: SEND_STATUS
	bcc @no ; card did not react -> no card
	tax
	bne @no ; first byte not $00 -> different card
	jsr spi_read
	tax
	bne @no ; second byte not $00 -> different card
	sec
	bra @yes

@no:	clc

@yes:	; restore sector
	; (this code preserves the C flag!)
	ldx #3
@2:	pla
	sta sector_lba, x
	dex
	bpl @2

	jsr sdcmd_end
	php
	plp
	rts
