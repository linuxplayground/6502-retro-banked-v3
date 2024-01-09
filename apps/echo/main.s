.include "../../rom/inc/kern.inc"
.include "../../rom/inc/io.inc"

.code
main:
        lda #<welcome
        ldx #>welcome
        jsr acia_puts
loop:
        jsr acia_getc
        cmp #$1b
        beq exit
        jsr acia_putc
        cmp #$0d
        bne :+
        lda #$0a
        jsr acia_putc
:
        jmp loop
exit:
        rts
        
.rodata
welcome: .byte $0a,$0d,"Welcome to demo of serial io.",$0a,$0d,0
