.globalzp vdp_ptr1

.export vdp_init, vdp_write_register, vdp_set_write_address, vdp_set_read_address
.export vdp_clear_vram, vdp_load_font, vdp_enable_text_80_mode


; memory mapped address of the F18A
F18A 						= $9F30
F18A_RAM					= F18A + 0
F18A_REG					= F18A + 1

; constants for vram tables
VDP_SPRITE_PATTERN_TABLE 	= $0
VDP_PATTERN_TABLE        	= $800
VDP_SPRITE_ATTRIBUTE_TABLE 	= $1000
VDP_NAME_TABLE 				= $1400
VDP_COLOR_TABLE				= $2000

; mdoe enum
.enum enum_vdp_mode
	text		; 0
	text_80		; 1
	g1			; 2
	g2			; 3
.endenum

.bss
vdp_mode:	.byte 0

.segment "VDPZP" : zeropage
vdp_ptr1: 	.res 2
vdp_ptr2:	.res 2

.code

; initialize the VDP into TEXT mode 40 column
vdp_init:
	lda #<vdp_text_mode_registers
	sta vdp_ptr1
	lda #>vdp_text_mode_registers
	sta vdp_ptr1 + 1

	ldx #0
@vdp_init_loop:
	lda (vdp_ptr1),y
	jsr vdp_write_register
	inx
	cpx #$8
	bne @vdp_init_loop
	lda enum_vdp_mode::text
	sta vdp_mode
	rts

; set a value in A to register in X
vdp_write_register:
	sta F18A_REG
	txa
	ora #$80
	sta F18A_REG
	rts

; set up the VDP RAM write address
; A is low byte, X is high byte
vdp_set_write_address:
	sta F18A_REG
	txa
	ora #$40
	sta F18A_REG
	rts

; set up the VDP RAM Read address
; A is low byte, X is high byte
vdp_set_read_address:
	sta F18A_REG
	txa
	sta F18A_REG
	rts

; clears all vdp ram (16k of it)
vdp_clear_vram:
	lda #$00
	ldx #$00
	jsr vdp_set_write_address
	lda #$ff
	sta vdp_ptr2
	lda #$3f
	sta vdp_ptr2 + 1
:	lda #$00
	sta F18A_RAM
	dec vdp_ptr1
	lda vdp_ptr1
	bne :-
	dec vdp_ptr1 + 1
	lda vdp_ptr1 + 1
	bne :-
	rts

; font_start in A/X, font_end in vdp_ptr1
vdp_load_font:
	sta vdp_ptr2
	stx vdp_ptr2 + 1

	lda #<VDP_PATTERN_TABLE
	ldx #>VDP_PATTERN_TABLE
	jsr vdp_set_write_address

	ldy #0
:	lda (vdp_ptr2)
	sta F18A_RAM
	lda vdp_ptr2
	clc
	adc #1
	sta vdp_ptr2
	lda #0
	adc vdp_ptr2 + 1
	sta vdp_ptr2 + 1
	cmp #>vdp_ptr1 + 1
	bne :-
	lda vdp_ptr1
	cmp #<vdp_ptr1
	bne :-
	rts


; Turns on 80 x 24 text mode - F18A only
vdp_enable_text_80_mode:
	lda #$04
	ldx #$00
	jsr vdp_write_register
	lda #$f0
	ldx #$01
	jsr vdp_write_register
	rts



.rodata
; F18 Setup registers
vdp_text_mode_registers:
	.byte $00	;r0
	.byte $F0	;r1 16kb ram + M1, interrupts enabled | text mode
	.byte $05	;r2 name table at 0x1400 
	.byte $80	;r3 color table at 0x2000
	.byte $01	;r4 pattern generator table at 0x800
	.byte $20   ;r5 sprite attributes table at 0x1000
	.byte $00   ;r6 sprite pattern table at 0x0000
	.byte $e1	;r7 forground color = grey, background color = black


