; vim: ft=asm_ca65
.include "../../rom/inc/vdp.inc"

.import popax

.export _vdp_load_font_wrapper

.code
;; void vdp_load_font(font, size);
_vdp_load_font_wrapper:
    sta $B2
    stx $B3
    jsr popax
    sta $B0
    stx $B1
    jmp $FF60

