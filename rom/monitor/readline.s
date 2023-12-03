.include "kern.inc"
.include "macros.inc"

.export readline, readline_init
.global inbuf, inbuf_end, strEndl

.code

readline_init:
        ldx inbuf_end - inbuf
:       stz inbuf,x
        dex
        bne :-
        rts

; receive input into inbuf until carriage return (0x0d) or 128 chars
readline:
        newline
        print strPrompt
        
        ldy #0
@loop:
        jsr acia_getc
        jsr acia_putc
        cmp #$0D
        beq @done
        cmp #$08
        beq @bs
        sta inbuf,y
        iny
        bpl @loop               ; as long as Y is positive (bit 7 = 0)
        bra @done
@bs:
        lda #' '                ; overwrite the last char with a space.
        jsr acia_putc
        lda #$08                ; go back once more
        jsr acia_putc
        dey                     ; move the pointer back
        bpl @loop               ; don't overflow past zero
        ldy #0
        bra @loop
@done:
        lda #0                  ; zero terminate
        sta inbuf,y
        lda #$0a
        jsr acia_putc
        tya                     ; return with count in y
        rts

.rodata
strPrompt:      .asciiz "SD> "