.import acia_init, acia_getc, acia_getc_nw, acia_putc, acia_puts
.import prbyte

.segment "JMPTBL"

jmp acia_init
jmp acia_getc
jmp acia_getc_nw
jmp acia_putc
jmp acia_puts
jmp prbyte