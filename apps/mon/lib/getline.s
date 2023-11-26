.importzp ptr1, ptr2, tmp1
.export getline

.include "kern.inc"

.code

; --------------------------------------------------------------------------------
; receive user input into a buffer
; buffer pointed to by ptr1
; size in A - max size is 255
; --------------------------------------------------------------------------------
getline:
        tax
        ldy     #0
getline_lp_0:
        jsr     acia_getc
        cmp     #$08
        beq     @backspace
        cmp     #$0D
        beq     @cr
        cmp     #$41
        bcc     @keyin
        cmp     #$41 + 26
        bcc     @keyin
        and     #$DF
@keyin:
        jsr     acia_putc
        sta     (ptr1),y
        iny
        dex
        bne     getline_lp_0
@cr:
        phy                     ; save num chars entered
        lda     #$0
        sta     (ptr1),y        ; add zero termination to line
        jsr     count_args
        pla                     ; restore num chars entered
        rts
@backspace:
        cpy     #0
        beq     getline_lp_0    ; don't backspace past start of line.
        jsr     acia_putc          ; issue backspace
        dey
        jmp     getline_lp_0


count_args:
        ldy     #0
        ldx     #0
@lp1:
        iny
        lda     (ptr1),y
        beq     @done
        cmp     #$20            ; was it a space
        bne     @lp1
        inx
        bra     @lp1            ; skip 1st space
@done:
        txa
        sta     (ptr2)
        rts