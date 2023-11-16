.include "zeropage.inc"
.include "sysram.inc"
.include "acia.inc"
.include "conio.inc"
.include "via.inc"
.include "wozmon.inc"
.include "xmodem.inc"
.include "lib.inc"
.include "banks.inc"

.import __LORAM_START__, __BANK_START__, rstfar
.export xstart, xend


LED     = %00000001
SD_CS   = %00010000
SD_SCK  = %00001000
SD_MOSI = %00000100
SD_MISO = %00000010

.bss
xstart: .res 2  ; holds the start address from xmodem
xend:   .res 2  ; holds the address of the last byte from xmodem

.code

_main:
        sei
        cld
        ldx     #$ff
        txs

        jsr     _acia_init
        stz     con_w_idx
        stz     con_r_idx

        stz     userirq
        stz     userirq + 1

        stz     ram_bank
        stz     rom_bank

        lda     #$6c      ; save jmp opcode to jmpfr.
        sta     jmpfr
        ; stz     jmpfr + 1 ; place holder for address to jump to
        ; stz     jmpfr + 2

        cli

        print   help_header
        print   help_body

loop:
        print prompt
        jsr     _cgetc
        jsr     _cputc
        cmp     #'b'
        beq     run_basic
        cmp     #'x'
        beq     run_xmodem
        cmp     #'r'
        beq     run_prog
        cmp     #'m'
        beq     run_wozmon
        cmp     #'h'
        beq     run_help
        print error
        jmp     loop

run_basic:
        lda     #BASICROM               ; switch to basic rom and reset
        jmp     rstfar
run_xmodem:
        sei
        jsr     _xmodem
        cli
        print   nl
        jmp     loop
run_prog:
        print   nl
        jsr     __LORAM_START__
        print   nl
        jmp     loop
run_wozmon:
        print   nl
        jsr     _wozmon
        jmp     loop
run_help:
        print   nl
        print   help_header
        print   help_body
        jmp     loop

nmi_handler:
        rti

irq_handler:
        pha
        phx
        phy
        cld

@acia_irq:
        bit     ACIA_STATUS
        bpl     @exit_irq
        jsr     _acia_getc
        ldx     con_w_idx
        sta     con_buf,x
        inc     con_w_idx
        bra     @exit_irq
@exit_irq:

        ply
        plx
        pla
        rti

service_user_irq:
        jmp     (userirq)

void_user_irq:
        rts


.rodata
help_header:
        .byte $0a,$0d
        .byte "+========================+", $0a, $0d
        .byte "|       6502-Retro       |", $0a, $0d
        .byte "+========================+", $0a, $0d
        .byte $0
help_body:
        .byte "| b-basic                |", $0a, $0d
        .byte "| x-load                 |", $0a, $0d
        .byte "| r-run                  |", $0a, $0d
        .byte "| m-monitor              |", $0a, $0d
        .byte "| h-help                 |", $0a, $0d
        .byte "+========================+", $0a, $0d
        .byte $0

prompt: .byte $0a, $0d, ">  ", $0
error:  .byte $0a, $0d, "Syntax error!", $0a, $0d, $0
nl:     .byte $0a, $0d, $0

.segment "VECTORS"
        .word nmi_handler
        .word _main
        .word irq_handler