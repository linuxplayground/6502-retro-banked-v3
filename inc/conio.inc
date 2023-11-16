.import _cgetc
.import _cputc
.import _cputs
.import _cgetc_nw
.import _write

.macro print addr
        lda     #<addr
        ldx     #>addr
        jsr     _cputs
.endmacro

.macro print_nl
        lda     #$0A
        jsr     _cputc
        lda     #$0D
        jsr     _cputc
.endmacro
