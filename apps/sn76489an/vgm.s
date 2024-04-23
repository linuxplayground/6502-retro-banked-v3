PORTB   = $9F20
PORTA   = $9F21
DDRB    = $9F22
DDRA    = $9F23
T1CL    = $9F24
T1CH    = $9F25
T1LL    = $9F26
T1LH    = $9F27
T2CL    = $9F28
T2CH    = $9F29
SR	   	= $9F2a
ACR		= $9F2b
PCR		= $9F2c
IFR		= $9F2d
IER		= $9F2e

SN_WE   = %00000100
SN_READY= %00001000

FIRST   = %10000000
SECOND  = %00000000
CHAN_1  = %00000000
CHAN_2  = %00100000
CHAN_3  = %01000000
CHAN_N	= %01100000
TONE    = %00000000
VOL     = %00010000
VOL_OFF = %00001111
VOL_MAX = %00000000

C1_SUSTAIN 	= $F0
C1_DECAY 	= $F1

FULL        = 64
HALF        = 32
QUARTER     = 16
EIGHTH		= 8
SIXTEENTH   = 4
THIRTYTOOTH = 2

.code
	jsr init_via_ports
	; Set up T1 timer in continuous interrupts mode for 50hz
	lda #%01000000
	sta ACR
	; Clock is 2mhz so 40hz is 50000 cycles
	; need to subtract 2 for the loop
	lda $4e
	sta T1CL
	lda $c3
	sta T1CH

	ldy #0
	lda song,y
song_loop:
	cmp #$ff
	beq :+
	jsr play_note
	lda T1CL		; clear interrupt / start over
:	lda song_times,y ; sustain
	tax
	jsr time
	phy
	lda song+1,y
	beq @last_decay
	ldy #$4
	jsr decay
	ply
	ldx #8			; pause between notes
	jsr time
	iny
	lda song,y
	jmp song_loop
@last_decay:
	ldy #$15
	jsr decay
	ply
end:
	jsr silence_all
	rts

time:
	lda #%01000000
wait_for_40hz:
	bit IFR
	beq wait_for_40hz
	lda T1CL
	dex
	bne time
	rts

; note index in A
play_note:
	tax
	lda notes,x
	ora #(FIRST|CHAN_1|TONE)
	jsr sn_send
	inx
	lda notes,x
	ora #(SECOND|CHAN_1|TONE)
	jsr sn_send
	lda #(FIRST|CHAN_1|VOL|$04)
	jsr sn_send
	rts

decay:
	ldx #$04			; match starting volume
	sty $F0

	lda #$69			; decay interval
	sta T1CL
	lda #$18
	sta T1CH

@loop:
	ldy $F0
	txa
	ora #(FIRST|CHAN_1|VOL)
	jsr sn_send
	lda #%01000000
@wait:
	bit IFR
	beq @wait
	lda T1CL
	dey
	bne @wait
	inx	
	cpx #$10
	bne @loop

	lda $4e	; reset timer to standard
	sta T1CL
	lda $c3
	sta T1CH
	rts

silence_all:
	lda #(FIRST|CHAN_1|VOL|VOL_OFF)
	jsr sn_send
	lda #(FIRST|CHAN_2|VOL|VOL_OFF)
	jsr sn_send
	lda #(FIRST|CHAN_3|VOL|VOL_OFF)
	jsr sn_send
	lda #(FIRST|CHAN_N|VOL|VOL_OFF)
	jsr sn_send
	rts

; Send a byte of data to the SN
; clobbers A
sn_send:
    sta PORTB               ; Put our data on the data bus
	lda PORTA				; get existing IO byte control
	eor #SN_WE				; toggle SN_WE (HIGH to LOW)
	sta PORTA				; save
	jsr wait_ready			; wait for SN to be ready
	lda PORTA				; get existing IO byte (wait_ready broke A)
	eor #SN_WE				; toggle SN_WE (LOW to HIGH)
	sta PORTA				; save
    rts

; Wait for the SN76489 to signal it's ready for more commands
wait_ready:
    lda PORTA
    and #SN_READY
	bne wait_ready
ready_done:
    rts

; set up IO Byte on VIA_PORTA
init_via_ports:
	lda DDRA		; enable SN_WE pin for output, preserve existing
	ora #SN_WE
	sta DDRA
	lda #%11111111	; all of PORTB is output.
	sta DDRB
	lda PORTA		; Start with a high on SN_WE
	ora #SN_WE
	sta PORTA
	rts

song:
	.byte $6e, $72, $78, $72, $80, $80, $76, $ff
	.byte $6e, $72, $78, $72, $7c, $78, $72, $ff
	.byte $6e, $72, $78, $72, $78, $7c, $76, $6e, $ff, $6e, $7c, $78
	.byte $00

song_times:
	.byte   4,   4,   4,   4,  16,  16,  32, 32 
	.byte   4,   4,   4,   4,  16,  16,  48, 32
	.byte   4,   4,   4,   4,  16,   4,  16, 16,    8,   4,  16,  32

.include "notes.asm"
