.import _acia_init
.import _acia_getc
.import _acia_putc
.import _acia_getc_nw
.import _acia_puts
.import _cgetc
.import _cputc
.import _cputs
.import _cgetc_nw
.import _delay_ms
.import _wozmon
.import _prbyte
.import _write
.import _primm
.import _rstfar
.import _jsfar

.import _rambankreg
.import _rombankreg
.import _via_portb
.import _via_porta
.import _via_ddrb
.import _via_ddra
.import _via_pcr
.import _via_ier

.macro print addr
        lda #<addr
        ldx #>addr
        jsr _cputs
.endmacro

.macro print_nl
        print strNewLine
.endmacro

.rodata
strNewLine:
        .byte $0a, $0d, $00