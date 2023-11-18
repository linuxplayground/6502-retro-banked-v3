.include "zeropage.inc"
.include "sysram.inc"
.include "acia.inc"
.include "conio.inc"
.include "via.inc"
.include "wozmon.inc"
.include "xmodem.inc"
.include "lib.inc"
.include "bank.inc"

.import  rstfar
.import __KERNRAM_LOAD__, __KERNRAM_RUN__, __KERNRAM_SIZE__

LORAM_START = $0800
LORAM_END   = $9EFF
BANK_BASE = $9F00

LED     = %00000001
SD_CS   = %00010000
SD_SCK  = %00001000
SD_MOSI = %00000100
SD_MISO = %00000010

.code

_main:
        sei
        cld
        ldx     #$ff
        txs

        jsr     _acia_init
        stz     con_w_idx
        stz     con_r_idx

        ; default bank is 01, bank 0 will be used by DOS.
        lda     #SYSTEMRAM
        sta     ram_bank
        sta     rambankreg

        stz     rom_bank

        ; clear kernal ram data
; clear kernal variables
;
	ldx #0          ;zero low memory
:	stz $0000,x     ;zero page
	stz $0200,x     ;user buffers and vars
	stz $0300,x     ;system space and user space
        stz $0400,x     ;"
	inx
	bne :-

        ; copy kernal bank code into KERNRAM
	ldx #<__KERNRAM_SIZE__
:	lda __KERNRAM_LOAD__-1,x
	sta __KERNRAM_RUN__-1,x
	dex
	bne :-
        
        ; set up indirect jmpfr after copy kernalram code.

        lda     #$6c      ; save jmp opcode to jmpfr.
        sta     jmpfr
.if DEBUG=0
        stz     jmpfr + 1 ; place holder for address to jump to
        stz     jmpfr + 2 ; this is commented for DEBUG Purposes
.endif

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
        jsr     LORAM_START
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
.segment "IRQVEC"
        .word irq_handler