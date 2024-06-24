; vim: ft=asm_ca65
.include "../../rom/inc/kern.inc"

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
CHAN_1   = %00000000
CHAN_2   = %00100000
CHAN_3   = %01000000
CHAN_N	= %01100000
TONE    = %00000000
VOL     = %00010000
VOL_OFF = %00001111
VOL_MAX = %00000000

.code
	jsr init_via_ports

	lda #$40		; 01000000
	sta IER			; Interrupt enable register
	lda $c0			; enable the timer
	sta ACR

	jsr silence_all

	ldx #36
:	lda notes,x
	inx
	ldy notes,x
	inx
	jsr play_note_chan_1
	jsr sixteenth
	jsr silence_all

	cpx #108
	beq :+
	bra :-
:	jsr silence_all	
	rts

silence_all:
	lda #(FIRST|CHAN_1|VOL|VOL_OFF)
	jsr sn_send
	lda #(SECOND|%00111111)
	jsr sn_send
	lda #(FIRST|CHAN_2|VOL|VOL_OFF)
	jsr sn_send
	lda #(SECOND|%00111111)
	jsr sn_send
	lda #(FIRST|CHAN_3|VOL|VOL_OFF)
	jsr sn_send
	lda #(SECOND|%00111111)
	jsr sn_send
	lda #(FIRST|CHAN_N|VOL|VOL_OFF)
	jsr sn_send
	lda #(SECOND|%00111111)
	jsr sn_send
	rts

play_note_chan_1:
    ORA #(FIRST|CHAN_1|TONE)
    JSR sn_send
    TYA
    ORA #(SECOND|CHAN_1|TONE)
    JSR sn_send
    LDA #(FIRST|CHAN_1|VOL|VOL_MAX)
    JSR sn_send
    LDA #(SECOND|CHAN_1|VOL|VOL_MAX)
    JSR sn_send
	jsr sixteenth
	jsr silence_all
    RTS

sn_send:
    PHX
    STA PORTB               ; Put our data on the data bus
    LDX #%00000100          ; Strobe WE
    STX PORTA
    LDX #%00000000
    STX PORTA
    JSR wait_ready          ; Wait for chip to be ready from last instruction
    LDX #%00000100
    STX PORTA
    PLX
    RTS

; Wait for the SN76489 to signal it's ready for more commands
wait_ready:
        PHA
ready_loop:
    LDA PORTA
    AND #%00001000
    BNE ready_loop
ready_done:
    PLA
    RTS

; note timing is a function of number of 25ms waits.
; Table of note lengths @60BPM
; 1.0   second = quarter note = 1000ms/25 = 40
; 0.5   second = eigth note = 5000ms/25 = 20
; 0.25  second = sixteenth note = 250ms/25 = 10
; 0.125 second = thirtysecond note = 125ms/25 = 5
quarter:
	phx
	ldx #40
	bra ms25
eighth:
	phx
	ldx #20
	bra ms25
sixteenth:
	phx
	ldx #10
	bra ms25
thirtysecond:
	phx
	ldx #5
	; fall through
ms25:	; wait 25 ms
	lda #$4e
	sta T2CL
	lda #$c3
	sta T2CH
	lda $20
ms25_wait:
	bit IFR
	beq ms25_wait
	dex
	bne ms25
	plx
	rts
	

init_via_ports:
	lda #(SD_SCK | SD_CS | SD_MOSI | SN_WE) ; set output pins, preserve SDCARD interface
	sta DDRA
	lda #%11111111	; all of PORTB is output.
	sta DDRB
	rts

.include "notes.asm"

