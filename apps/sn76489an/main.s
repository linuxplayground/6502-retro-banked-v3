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

SD_SCK  = %00000001
SD_CS   = %00000010
SN_WE   = %00000100
SD_MOSI = %10000000


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

.code
	jsr init_via_ports

	; enable T2 interrupts
	lda #%01000000 ; Bit 6 = 1 continuous interrupt Bit 5 Timer 2 one shot mode
	sta ACR		   ; 
	lda #$4e
	sta T1CL
	lda #$c3
	sta T1CH

	; 
	jsr silence_all

	ldx #$00;
loop:
	lda notes,x
	inx
	ldy notes,x
	inx
	jsr play_note_chan_1
	lda #$00
	sta C1_SUSTAIN

wait:
	lda #%01000000	; test for T1 interrupt
wait_frame:
	bit IFR
	beq wait_frame
	lda T1CL		; clear T1 interrupt flag
	lda C1_SUSTAIN
	beq :+
	dec C1_SUSTAIN
	bra wait
:	lda C1_DECAY
	cmp #$0f
	beq :+
	inc C1_DECAY
	jsr set_chan_1_vol
	bra wait
:
	;cpx #$a6
	cpx #24
	bne loop

	jsr silence_all

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

set_chan_1_vol:
	ORA #(FIRST|CHAN_1|VOL)
	JSR sn_send
	rts

play_note_chan_1:
    ORA #(FIRST|CHAN_1|TONE)
    JSR sn_send
    TYA
    ORA #(SECOND|CHAN_1|TONE)
    JSR sn_send
	LDA #(FIRST|CHAN_1|VOL|$04)	; starting at volume 4, not max.
    JSR sn_send
	lda #$04
	sta C1_DECAY
    RTS

sn_send:
    STA PORTB               ; Put our data on the data bus
    LDA PORTA
	EOR #SN_WE
	STA PORTA
	JSR wait_ready
	LDA PORTA
	EOR #SN_WE
	STA PORTA
    RTS

; Wait for the SN76489 to signal it's ready for more commands
wait_ready:
ready_loop:
    LDA PORTA
    AND #%00001000
    BNE ready_loop
ready_done:
    RTS

; note timing is a function of number of 25ms waits.
; Table of note lengths @60BPM
; 1.0   second = quarter note = 1000ms/25 = 40
; 0.5   second = eigth note = 5000ms/25 = 20
; 0.25  second = sixteenth note = 250ms/25 = 10
; 0.125 second = thirtysecond note = 125ms/25 = 5


init_via_ports:
	lda DDRA
	ora #SN_WE
	sta DDRA
	lda #%11111111	; all of PORTB is output.
	sta DDRB
	rts

.include "notes.asm"

