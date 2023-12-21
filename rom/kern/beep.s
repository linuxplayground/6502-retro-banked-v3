.include "io.inc"
.export beep
.globalzp tmp1
.code

beep:
        lda via_ddra
        sta tmp1
        lda #1
        sta via_ddra
        sta via_porta
        sta via_porta
        ldx #0
:       ldy #80
:       dey
        bne :-
        dex
        bne :--
        stz via_porta
        lda tmp1
        sta via_ddra
        rts