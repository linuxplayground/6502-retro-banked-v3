.include "zeropage.inc"

.export _delay_ms, primm, _primm
.import _cputc

.code

_delay_ms:
      sta   tmp1
      txa
      pha
      tya
      pha
      ldx   tmp1
      ldy   #190
@loop1:
      dey
      bne   @loop1

@loop2:
      dex
      beq    @return
      nop
      ldy   #198
@loop3:
      dey
      bne   @loop3
      jmp   @loop2
@return:
      pla
      tay
      pla
      tax
      lda   tmp1
      rts

; print immediate
_primm:
primm:
      pla
      sta   ptr1
      pla
      sta   ptr1+1
      bra   @primm3
@primm2:
      jsr   _cputc
@primm3:
      inc   ptr1
      bne   @primm4
      inc   ptr1+1
@primm4:
      lda   (ptr1)
      bne   @primm2
      lda   ptr1+1
      pha
      lda   ptr1
      pha
      rts