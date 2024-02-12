; vim: ft=asm_ca65
.import acia_putc
.globalzp krn_ptr1
.export primm
.code
;------------------------------------------------------------------------
; Print immediate
;------------------------------------------------------------------------
primm:
      pla
      sta   krn_ptr1
      pla
      sta   krn_ptr1+1
      bra   @primm3
@primm2:
      jsr   acia_putc
@primm3:
      inc   krn_ptr1
      bne   @primm4
      inc   krn_ptr1+1
@primm4:
      lda   (krn_ptr1)
      bne   @primm2
      lda   krn_ptr1+1
      pha
      lda   krn_ptr1
      pha
      rts
