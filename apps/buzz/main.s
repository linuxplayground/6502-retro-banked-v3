DDRB  = $9F22
T1CL	= $9F24
T1CH	= $9F25
T2CL	= $9F28
T2CH	= $9F29
ACR		= $9F2b
PCR		= $9F2c
IFR		= $9F2d
IER		= $9F2e

.code
  lda #$ff
  sta DDRB

	lda #$40        ; 01000000
	sta IER         ; Interrupt Enable Register

	lda #$c0        ; enable the timer (11000000)
	sta ACR

	lda #$00		; start the timer
	sta T1CL
	sta T1CH

play:
 
	ldx #$06
	lda #$70
	sta T1CL
	lda #$04
	sta T1CH
again:
	lda #$4e	; wait for 0.05 seconds
	sta T2CL
	lda #$c3
	sta T2CH
	lda #$20
wait:
	bit IFR
	beq wait
	dex
	bne again	; keep waiting until duration is up.

end:
	lda #$00
	sta ACR     ; turn off timer.

	rts

