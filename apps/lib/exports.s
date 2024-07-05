; vim: ft=asm_ca65
; ACIA
.export _acia_getc       := $FF03
.export _acia_getc_nw    := $FF06
.export _acia_putc       := $FF09
.export _acia_puts       := $FF0C
.export _prbyte          := $FF0F

; AUDIO
.export _beep            := $FF12

; VDP
.export _vdp_unlock      := $FF4B
.export _vdp_80_col      := $FF48
.export _vdp_init_textmode := $FF57
.export _vdp_load_font   := $FF60
.export _vdp_clear_screen := $FF54
.export _vdp_print       := $FF51
.export _vdp_write_reg   := $FF5A
.export _vdp_write_char  := $FF66
.export _vdp_write_address := $FF5D
.export _vdp_newline     := $FF63
.export _vdp_console_out := $FF69

.export _vdp               := $B500
.export _vdpptr1 :absolute := $00B0
.export _vdpptr2 :absolute := $00B2
.export _vdpptr3 :absolute := $00B4

