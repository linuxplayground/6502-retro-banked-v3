.import _vdp_console_out
.import acia_putc,acia_puts,_vdp_print
.export cout,cprint
.code
cout:
    pha
    jsr _vdp_console_out
    pla
    jsr acia_putc
    rts

cprint:
    pha
    phx
    jsr acia_puts
    plx
    pla
    jsr _vdp_print
    rts

