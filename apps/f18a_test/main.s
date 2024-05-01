; vim: ft=asm_ca65
.include "vdp.inc"
.include "kern.inc"
.include "kern_vdp.inc"

;.import _vdp_80_col, _vdp_unlock, _vdp_lock, _vdp_print, _vdp_clear_screen
;.import _vdp_init_textmode, _vdp_write_reg, _vdp_write_address, _vdp_load_font
;.import _vdp_newline, _vdp_write_char, _vdp_console_out
;
.global vdp
.globalzp vdpptr1, vdpptr2, vdpptr3

vdp     = $B500
vdpptr1 = $B0
vdpptr2 = $B2
vdpptr3 = $B4

.code
main:
 
   jsr _vdp_unlock                 ; must unlock if you want vram tables to not be on 4k boundaries
                                   ; for things like 80column mode
   jsr _vdp_init_textmode          ; sets up standard 40x24 text mode with white on blue
   jsr _vdp_80_col                 ; enable 80 column mode

   set16 vdpptr1, font80           ; load_font needs a ptr to the start of the font and
   set16 vdpptr2, $0400            ; the size of the font.
   jsr _vdp_load_font

   jsr _vdp_clear_screen           ; clear screen is aware of the larger name table in the event
                                   ; of 80colum mode

   vdp_set_write_address vdp + sVdp::nametable



    lda #<str_hello
    ldx #>str_hello
    jsr _vdp_print

    jsr _vdp_newline

    lda #<str_prompt
    ldx #>str_prompt
    jsr _vdp_print

@loop:
    jsr acia_getc
    cmp #$1b
    beq @end
    jsr _vdp_console_out
    bra @loop
@newline:
    jsr _vdp_newline
    bra @loop
@end:
    ; return to the monitor.
    rts


.rodata
str_hello: .byte "Hello, World!",0
str_prompt: .byte "> ",0
font80:
    .include "font_80.s"
