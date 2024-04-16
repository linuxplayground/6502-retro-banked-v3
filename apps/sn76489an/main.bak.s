.include "kern.inc"

PORTB    = $9F20
PORTA    = $9F21
DDRB     = $9F22
DDRA     = $9F23

FIRST 	 = %10000000
SECOND   = %00000000
CHAN_1 	 = %00000000
CHAN_2   = %00100000
CHAN_3   = %01000000
CHAN_N   = %01100000
TONE     = %00000000
VOLUME   = %00010000
VOL_OFF  = %00001111
VOL_MAX  = %00000000

SN_WE    = %00001000

F_C  = $03	;  262
S_C  = $2f	;  0011101111
F_CS = $03	;  277
S_CS = $22	;  0011100010
F_D  = $03	;  294
S_D  = $15	;  0011010101
F_DS = $03	;  311
S_DS = $09	;  0011001001
F_E  = $02	;  330
S_E  = $3d	;  0010111101
F_F  = $02	;  349
S_F  = $33	;  0010110011
F_FS = $02	;  370
S_FS = $29	;  0010101001
F_G  = $02	;  392
S_G  = $1f	;  0010011111
F_GS = $02	;  415
S_GS = $17	;  0010010111
F_A  = $02	;  440
S_A  = $0e	;  0010001110
F_AS = $02	;  466
S_AS = $06	;  0010000110
F_B  = $01	;  494
S_B  = $3f	;  0001111111

.code
	lda PORTA
	ora #SN_WE	; makes write enable an output 
	sta DDRA
	lda #%11111111 ; make port B all output
	sta DDRB

	jsr silence_all

	; play all the notes
	ldx #0
song_loop:
	lda song_firsts,x
	beq song_done
	ldy song_seconds,x
	jsr play_note
	jsr silence_all
	jsr beat
	inx
	jmp song_loop

song_done:
	jsr silence_all
	rts

silence_all:
	pha
	lda #(FIRST|CHAN_1|VOLUME|VOL_OFF)
	jsr sn_send
	lda #(SECOND|%00111111)
	jsr sn_send
	lda #(FIRST|CHAN_2|VOLUME|VOL_OFF)
	jsr sn_send
	lda #(SECOND|%00111111)
	jsr sn_send
	lda #(FIRST|CHAN_3|VOLUME|VOL_OFF)
	jsr sn_send
	lda #(SECOND|%00111111)
	jsr sn_send
	lda #(FIRST|CHAN_N|VOLUME|VOL_OFF)
	jsr sn_send
	lda #(SECOND|%00111111)
	jsr sn_send
	pla
	rts


play_note:
	ora #(FIRST|CHAN_1|TONE)
	jsr sn_send
	tya
	ora #(SECOND|CHAN_1|TONE)
	jsr sn_send
	lda #(FIRST|CHAN_1|VOLUME|VOL_MAX)
	jsr sn_send
	lda #(SECOND|CHAN_1|VOLUME|VOL_MAX)
	jsr sn_send
	jsr beat
	rts

sn_send:
	sta PORTB

	lda PORTA
	ora #SN_WE
	sta PORTA

	eor #SN_WE
	sta PORTA

	jsr sleep

	lda PORTA
	ora #SN_WE
	sta PORTA
	rts

sleep:
	phy
	ldy #5
sleep2:
	dey
	bne sleep2
	ply
	rts

beat:
	phy
	phx
	ldy #$F0
beat2:
	ldx #$ff
beat3:
	dex
	bne beat3
	dey
	bne beat2
	plx
	ply
	rts

.rodata

song_firsts:
	.byte F_C
	.byte F_CS
	.byte F_D
	.byte F_DS
	.byte F_E
	.byte F_F
	.byte F_FS
	.byte F_G
	.byte F_GS
	.byte F_A
	.byte F_AS
	.byte F_B
	.byte 0

song_seconds:
	.byte S_C
	.byte S_CS
	.byte S_D
	.byte S_DS
	.byte S_E
	.byte S_F
	.byte S_FS
	.byte S_G
	.byte S_GS
	.byte S_A
	.byte S_AS
	.byte S_B
	.byte 0

