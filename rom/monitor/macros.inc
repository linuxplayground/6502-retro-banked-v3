; vim: ft=asm_ca65
.macro newline
	pha
	phx
	lda #<strEndl
	ldx #>strEndl
	jsr acia_puts
	plx
	pla
.endmacro

.macro print addr
	pha
	phx
	lda #<addr
	ldx #>addr
	jsr acia_puts
	plx
	pla
.endmacro
