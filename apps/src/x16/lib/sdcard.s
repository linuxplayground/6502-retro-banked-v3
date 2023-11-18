.include "zeropage.inc"
.include "kernal.inc"

SD_CS   = %00010000
SD_SCK  = %00001000
SD_MOSI = %00000100
SD_MISO = %00000010
PORTA_OUTPUTPINS =  SD_CS | SD_SCK | SD_MOSI

VIA_PORTA = _via_porta
VIA_DDRA = _via_ddra

.export _sd_init, _sd_readsector
.global sd_lba, sd_sector_buffer

.globalzp sdptr

.segment "DOSZP": zeropage
sdptr:  .res 2

.bss
sd_lba: .res 4

.segment "BUFFERS"
sd_sector_buffer: .res 512

.code
_sd_init:
        lda #PORTA_OUTPUTPINS
        sta _via_ddra

        ; Let the SD card boot up, by pumping the clock with SD CS disabled

        ; We need to apply around 80 clock pulses with CS and MOSI high.
        ; Normally MOSI doesn't matter when CS is high, but the card is
        ; not yet is SPI mode, and in this non-SPI state it does care.

        lda #SD_CS | SD_MOSI
        ldx #160               ; toggle the clock 160 times, so 80 low-high transitions
@preinitloop:
        eor #SD_SCK
        sta VIA_PORTA
        dex
        bne @preinitloop


        lda #10
        sta tmp1
@cmd0: ; GO_IDLE_STATE - resets card to idle state, and SPI mode
        lda #<sd_cmd0_bytes
        sta sdptr
        lda #>sd_cmd0_bytes
        sta sdptr+1

        jsr _sd_sendcommand

        ; Expect status response $01 (not initialized)
        cmp #$01
        beq @cmd8
        dec tmp1
        bne @cmd0
        jmp @initfailed


@cmd8: ; SEND_IF_COND - tell the card how we want it to operate (3.3V, etc)
        lda #<sd_cmd8_bytes
        sta sdptr
        lda #>sd_cmd8_bytes
        sta sdptr+1

        jsr _sd_sendcommand

        ; Expect status response $01 (not initialized)
        cmp #$01
        bne @initfailed

        ; Read 32-bit return value, but ignore it
        jsr _sd_readbyte
        jsr _sd_readbyte
        jsr _sd_readbyte
        jsr _sd_readbyte

@cmd55: ; APP_CMD - required prefix for ACMD commands
        lda #<sd_cmd55_bytes
        sta sdptr
        lda #>sd_cmd55_bytes
        sta sdptr+1

        jsr _sd_sendcommand

        ; Expect status response $01 (not initialized)
        cmp #$01
        bne @initfailed

@cmd41: ; APP_SEND_OP_COND - send operating conditions, initialize card
        lda #<sd_cmd41_bytes
        sta sdptr
        lda #>sd_cmd41_bytes
        sta sdptr+1

        jsr _sd_sendcommand

        ; Status response $00 means initialised
        cmp #$00
        beq @initialized

        ; Otherwise expect status response $01 (not initialized)
        cmp #$01
        bne @initfailed

        lda #$20
        jsr _delay_ms
        jmp @cmd55

@initialized:
        rts
@initfailed:
        lda #'X'
        jsr _cputc
@loop:
        rts

_sd_writebyte:
        ; Tick the clock 8 times with descending bits on MOSI
        ; SD communication is mostly half-duplex so we ignore anything it sends back here

        ldx #8                      ; send 8 bits

@loop:
        asl                         ; shift next bit into carry
        tay                         ; save remaining bits for later

        lda #0
        bcc @sendbit                ; if carry clear, don't set MOSI for this bit
        ora #SD_MOSI

@sendbit:
        sta VIA_PORTA                   ; set MOSI (or not) first with SCK low
        eor #SD_SCK
        sta VIA_PORTA                   ; raise SCK keeping MOSI the same, to send the bit

        tya                         ; restore remaining bits to send

        dex
        bne @loop                   ; loop if there are more bits to send

        rts

_sd_readbyte:
        ; Enable the card and tick the clock 8 times with MOSI high,
        ; capturing bits from MISO and returning them

        ldx #$fe    ; Preloaded with seven ones and a zero, so we stop after eight bits

@loop:

        lda #SD_MOSI                ; enable card (CS low), set MOSI (resting state), SCK low
        sta VIA_PORTA

        lda #SD_MOSI | SD_SCK       ; toggle the clock high
        sta VIA_PORTA

        lda VIA_PORTA                   ; read next bit
        and #SD_MISO

        clc                         ; default to clearing the bottom bit
        beq @bitnotset              ; unless MISO was set
        sec                         ; in which case get ready to set the bottom bit
@bitnotset:

        txa                         ; transfer partial result from X
        rol                         ; rotate carry bit into read result, and loop bit into carry
        tax                         ; save partial result back to X

        bcs @loop                   ; loop if we need to read more bits

        rts




_sd_sendcommand:

        jsr sd_command_start

        ldy #0
        lda (sdptr),y    ; command byte
        jsr _sd_writebyte
        ldy #1
        lda (sdptr),y    ; data 1
        jsr _sd_writebyte
        ldy #2
        lda (sdptr),y    ; data 2
        jsr _sd_writebyte
        ldy #3
        lda (sdptr),y    ; data 3
        jsr _sd_writebyte
        ldy #4
        lda (sdptr),y    ; data 4
        jsr _sd_writebyte
        ldy #5
        lda (sdptr),y    ; crc
        jsr _sd_writebyte

        jsr sd_waitresult

        pha

        ; End command
        jsr sd_command_end

        pla   ; restore result code
        rts

sd_command_end:
        pha
        lda #$ff
        jsr _sd_writebyte
        jsr sd_nothing_byte
        jsr sd_nothing_byte
        lda #SD_CS | SD_MOSI   ; set CS high again
        sta VIA_PORTA
        pla
        rts

sd_nothing_byte:
        ldx #8
@command_start_bit:
        lda #(SD_MOSI | SD_CS)
        sta VIA_PORTA
        lda #(SD_SCK | SD_MOSI | SD_CS)
        sta VIA_PORTA
        dex
        cpx #0
        bne @command_start_bit
        rts

sd_waitresult:
        ; Wait for the SD card to return something other than $ff
        jsr _sd_readbyte
        cmp #$ff
        beq sd_waitresult
        rts

sd_command_start:
        pha
        lda #SD_MOSI           ; pull CS low to begin command
        sta VIA_PORTA
        jsr sd_nothing_byte
        jsr sd_nothing_byte
        lda #$ff
        jsr _sd_writebyte
        pla
        rts

_sd_readsector:
        ; Read a sector from the SD card.  A sector is 512 bytes.
        ;
        ; Parameters:
        ;    sd_lba        32-bit sector number
        ;    sdptr              address of buffer to receive data

        lda #SD_MOSI
        sta VIA_PORTA

        ; Command 17, arg is sector number, crc not checked
        lda #$51                    ; CMD17 - READ_SINGLE_BLOCK
        jsr _sd_writebyte
        lda sd_lba+3   ; sector 24:31
        jsr _sd_writebyte
        lda sd_lba+2   ; sector 16:23
        jsr _sd_writebyte
        lda sd_lba+1   ; sector 8:15
        jsr _sd_writebyte
        lda sd_lba     ; sector 0:7
        jsr _sd_writebyte
        lda #$01                    ; crc (not checked)
        jsr _sd_writebyte

        jsr sd_waitresult
        cmp #$00
        bne sd_fail

        ; wait for data
        jsr sd_waitresult
        cmp #$fe
        bne sd_fail

        ; Need to read 512 bytes - two pages of 256 bytes each
        jsr @readpage
        inc sdptr+1
        jsr @readpage
        dec sdptr+1

        ; End command
        lda #SD_CS | SD_MOSI
        sta VIA_PORTA

        rts
@readpage:
        ; Read 256 bytes to the address at sdptr
        ldy #0
@readloop:
        jsr _sd_readbyte
        sta (sdptr),y
        iny
        bne @readloop
        rts

sd_fail:
        lda #'s'
        jsr _cputc
        lda #':'
        jsr _cputc
        lda #'f'
        jsr _cputc
        rts

.rodata
sd_cmd0_bytes:
        .byte $40, $00, $00, $00, $00, $95
sd_cmd8_bytes:
        .byte $48, $00, $00, $01, $aa, $87
sd_cmd55_bytes:
        .byte $77, $00, $00, $00, $00, $01
sd_cmd41_bytes:
        .byte $69, $40, $00, $00, $00, $01