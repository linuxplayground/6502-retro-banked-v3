.include "acia.inc"
.import acia_init, acia_getc, acia_getc_nw, acia_putc, acia_puts
.code
main:
        jsr acia_getc
        jsr acia_putc
        jmp main