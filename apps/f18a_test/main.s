.include "math.inc"

VDP_SPRITE_PATTERN_TABLE    = 0
VDP_PATTERN_TABLE           = $800
VDP_SPRITE_ATTRIBUTE_TABLE  = $1000
VDP_NAME_TABLE              = $1400
VDP_COLOR_TABLE             = $2000

VDP_TEXT_MODE_WIDTH         = 40
VDP_GRAPHICS_MODE_WIDTH     = 32
VDP_TEXT_MODE               = 0
VDP_G1_MODE                 = 1
VDP_G2_MODE                 = 2


__TMS_START__ = $9F30
VDP_VRAM                = __TMS_START__ + $00   ; TMS Mode 0
VDP_REG                 = __TMS_START__ + $01   ; TMS Mode 1

vdp_ptr = $f0
vdp_x = $f2
vdp_y = $f3
vdp_vsync_ticks = $f4
vdp_tmp = $f6

buffer = $A000
;buffer_end = $A480
buffer_end = $AA00

.macro vdp_set_write_address addr
        lda #<addr
        ldx #>addr
        jsr _vdp_set_write_address
.endmacro

.macro vdp_ptr_to_vram_write_addr
        lda vdp_ptr
        ldx vdp_ptr + 1
        jsr _vdp_set_write_address
.endmacro

.macro vdp_ptr_to_vram_read_addr
        lda vdp_ptr
        ldx vdp_ptr + 1
        jsr _vdp_set_read_address
.endmacro

.macro vdp_vdp_xy_to_ptr
        ldx vdp_x
        ldy vdp_y
        jsr _vdp_xy_to_ptr
.endmacro

.macro vdp_write_reg reg, val
        ldx reg
        lda val
        jsr _vdp_write_reg
.endmacro

.macro vdp_set_text_color fg, bg
        lda #fg
        asl
        asl
        asl
        asl
        ora #bg
        ldx #7
        jsr _vdp_write_reg
.endmacro

.macro vdp_con_g1_mode
        lda #$E0
        ldx #$01
        jsr _vdp_write_reg
.endmacro

        .code

main:
	.repeat 2
	lda #$1C
	sta VDP_REG
	lda #($80 | $39)
	sta VDP_REG
	.endrepeat

	jsr _vdp_reset

	lda #$40			; enable 30 row mode
	sta VDP_REG
	lda #($80 | $31)
	sta VDP_REG

	jsr vdp_clear_buffer

	
	lda #$20
	sta vdp_x
@fill_buffer:
	lda #<buffer
	sta vdp_ptr
	lda #>buffer
	sta vdp_ptr + 1
@fill_buffer_loop:
	lda vdp_x
	sta (vdp_ptr)
	lda vdp_ptr
	clc
	adc #1
	sta vdp_ptr
	lda vdp_ptr + 1
	adc #0
	sta vdp_ptr + 1
	cmp #>buffer_end
	bne @fill_buffer_loop
	lda #15
	jsr vdp_delay
	jsr vdp_flush
	inc vdp_x
	lda vdp_x
	cmp #$7F
	bne @fill_buffer
	;lda #$20
	;sta vdp_x
	;jmp @fill_buffer

	rts

str_message: .byte "Hello, World",0

vdp_clear_buffer:
	lda #<buffer
	sta vdp_ptr
	lda #>buffer
	sta vdp_ptr + 1
:
	lda #' '
	sta (vdp_ptr)
	lda vdp_ptr
	clc
	adc #1
	sta vdp_ptr
	lda vdp_ptr + 1
	adc #0
	sta vdp_ptr + 1
	cmp #>buffer_end
	bne :-
	rts

vdp_delay:
	tax
@delay_loop:
	jsr vdp_wait
	dex
	bne @delay_loop
	rts

vdp_wait:
	lda VDP_REG
	and #$80
	beq vdp_wait
	rts

vdp_flush:
	vdp_set_write_address VDP_NAME_TABLE
	lda #<buffer
	sta vdp_ptr
	lda #>buffer
	sta vdp_ptr + 1
	ldy #0
:
	lda (vdp_ptr)
	sta VDP_VRAM
	clc
	lda vdp_ptr
	adc #1
	sta vdp_ptr
	lda vdp_ptr + 1
	adc #0
	sta vdp_ptr + 1
	cmp #>buffer_end
	bne :-
	rts

; -----------------------------------------------------------------------------
; VDP Reset Routine
; -----------------------------------------------------------------------------
_vdp_reset:
        jsr vdp_clear_ram
        jsr vdp_init_registers                  ; defaults to text mode
        jsr vdp_init_patterns
;		vdp_con_g1_mode
     ;   jsr vdp_init_colors
		jsr _vdp_clear_screen
        rts

; -----------------------------------------------------------------------------
; Fill screen with spaces.
; -----------------------------------------------------------------------------
_vdp_clear_screen:
        vdp_set_write_address VDP_NAME_TABLE
        ldx #4
        lda #' '
:       ldy #0
:       sta VDP_VRAM
        iny
        bne :-
        dex
        bne :--
        rts
; -----------------------------------------------------------------------------
; Get data from screen name table.
; A contains data at vdp_ptr
; -----------------------------------------------------------------------------
_vdp_get:
        lda VDP_VRAM
        rts

; -----------------------------------------------------------------------------
; Write a byte to the VDP at address pointed to by vdp_ptr
; A contains the byte to write. vdp_ptr already points to location to write to
; -----------------------------------------------------------------------------
_vdp_put:
        sta VDP_VRAM
        rts
; -----------------------------------------------------------------------------
; Set VDP Write address to address defined by A=lsb, X=msb
; -----------------------------------------------------------------------------
_vdp_set_write_address:
        sta VDP_REG
        txa
        ora #$40
        sta VDP_REG
        rts
; -----------------------------------------------------------------------------
; Set VDP Read address to address defined by A=lsb, X=msb
; -----------------------------------------------------------------------------
_vdp_set_read_address:
        sta VDP_REG
        txa
        sta VDP_REG
        rts

; -----------------------------------------------------------------------------
; VDP Write Register - A = Data, X = reg num
; -----------------------------------------------------------------------------
_vdp_write_reg:
        sta VDP_REG
        txa
        ora #$80
        sta VDP_REG
        rts

; -----------------------------------------------------------------------------
; Clear all of the memory in the VDP
; -----------------------------------------------------------------------------
vdp_clear_ram:
        lda #0
        sta VDP_REG
        ora #$40
        sta VDP_REG
        lda #$FF
        sta vdp_ptr
        lda #$3F
        sta vdp_ptr + 1
@clr_1:
        lda #$00
        sta VDP_VRAM
        dec vdp_ptr
        lda vdp_ptr
        bne @clr_1
        dec vdp_ptr + 1
        lda vdp_ptr + 1
        bne @clr_1
        rts

; -----------------------------------------------------------------------------
; Disable Interrupts
; -----------------------------------------------------------------------------
_vdp_disable_interrupts:
        ldx #$01
        lda #$D0
        jsr _vdp_write_reg
        rts

; -----------------------------------------------------------------------------
; Enable Interrupts
; -----------------------------------------------------------------------------
_vdp_enable_interrupts:
        ldx #$01
        lda #$F0
        jsr _vdp_write_reg
        rts

; -----------------------------------------------------------------------------
; Set up Graphics Mode 1 - see init defaults at the end of this file.
; -----------------------------------------------------------------------------
vdp_init_registers:
        ldx #$00
:       lda vdp_inits,x
        sta VDP_REG
        txa
        ora #$80
        sta VDP_REG
        inx
        cpx #8
        bne :-
        rts

; -----------------------------------------------------------------------------
; Initialise the pattern table. (font)
; -----------------------------------------------------------------------------
vdp_init_patterns:
        vdp_set_write_address VDP_PATTERN_TABLE

        lda #<patterns
        sta vdp_ptr
        lda #>patterns
        sta vdp_ptr + 1
        ldy #0
:
        lda (vdp_ptr),y
        sta VDP_VRAM
        lda vdp_ptr
        clc
        adc #1
        sta vdp_ptr
        lda #0
        adc vdp_ptr + 1
        sta vdp_ptr + 1
        cmp #>end_patterns
        bne :-
        lda vdp_ptr
        cmp #<end_patterns
        bne :-
        rts

; -----------------------------------------------------------------------------
; Initialise the color table.
; -----------------------------------------------------------------------------
vdp_init_colors:
        vdp_set_write_address VDP_COLOR_TABLE

        lda #<colors
        sta vdp_ptr
        lda #>colors
        sta vdp_ptr + 1
        ldy #0
:       lda (vdp_ptr),y
        sta VDP_VRAM
        lda vdp_ptr
        clc
        adc #1
        sta vdp_ptr
        lda #0
        adc vdp_ptr + 1
        sta vdp_ptr + 1
        cmp #>end_colors
        bne :-
        lda vdp_ptr
        cmp #<end_colors
        bne :-
        rts
;=============================================================================
;     DATA
;=============================================================================
str_prompt:
        .asciiz "> "
str_nl: .byte $0d,$0a,$00

vdp_inits:
reg_0: .byte $04                ; r0
reg_1: .byte $F0                ; r1 16kb ram + M1, interrupts enabled, text mode
reg_2: .byte $05                ; r2 name table at 0x1400
reg_3: .byte $80                ; r3 color start 0x2000
reg_4: .byte $01                ; r4 pattern generator start at 0x800
reg_5: .byte $20                ; r5 Sprite attriutes start at 0x1000
reg_6: .byte $00                ; r6 Sprite pattern table at 0x0000
reg_7: .byte $E1                ; r7 Set forground and background color (grey on black)
vdp_inits_end:

patterns:
	.include "font_80.s"
end_patterns:

; in graphics 1 mode, these colors refer to the patterns in groups
; of 8.  Each byte covers 8 patterns.  so pattern 90 for example is covered by color $34
; in this table.  0x3 is the forground color (light green) and 0x4 is the background color
; (blue)
colors:
        .byte $e4,$e4,$e4,$e4,$e4,$e4,$e4,$e4   ; 00 - 3F
        .byte $e4,$e4,$e4,$e4,$e4,$e4,$e4,$e4   ; 40 - 7F
        .byte $e4,$e4,$e4,$e4,$e4,$e4,$e4,$e4   ; 80 - BF
        .byte $e4,$e4,$e4,$e4,$e4,$e4,$e4,$e4   ; C0 - FF
        .byte $e4,$e4,$e4,$e4,$e4,$e4,$e4,$e4   ; 00 - 3F
        .byte $e4,$e4,$e4,$e4,$e4,$e4,$e4,$e4   ; 40 - 7F
        .byte $e4,$e4,$e4,$e4,$e4,$e4,$e4,$e4   ; 80 - BF
        .byte $e4,$e4,$e4,$e4,$e4,$e4,$e4,$e4   ; C0 - FF
end_colors:
