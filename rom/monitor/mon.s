; vim: ft=asm_ca65
.include "io.inc"
.include "banks.inc"
.include "macros.inc"
.include "vdp.inc"

.import acia_init, acia_getc, acia_getc_nw, acia_putc, acia_puts
.import jsrfar, init_ram, shared_vars, shared_vars_len
.import wozmon, xmodem
.import dos_init, strAnsiCLSHome
.import readline, readline_init, read_address_from_input, address, inbuf
.import sn_start, sn_beep, sn_stop

.globalzp ram_bank, rom_bank, ptr1, krn_ptr1

.global strEndl
.global vdp

.code
main:
    sei
    cld
    ldx #$ff
    txs

    jsr sn_start
    jsr sn_beep
    jsr sn_stop

    jsr init_ram

    jsr acia_init

    lda DOS_BANK
    sta rom_bank
    sta ram_bank
    sta rambankreg
    nop
    nop

    ; for the longest time I struggled to debug why opening files was failing for me.
    ; turns out these BSS Variables declared in dos.s must be initialised to zero.
    ; CA65 does not initialise BSS data to 0 by default.
    ldx #<shared_vars_len
:       stz shared_vars+$ff,x
    dex
    bne :-

    ldx #0
:       stz shared_vars,x
    inx
    bne :-

    ; reset vdp_tick
    stz vdp + sVdp::tick

    cli

    ; start
    ;
    print strAnsiCLSHome
    print strWelcome
    print strHelp

    ;

loop:
    lda #<prompt
    ldx #>prompt
    jsr acia_puts

    jsr acia_getc
    jsr acia_putc
    cmp #'b'
    beq run_basic
    cmp #'d'
    beq run_dos
    cmp #'p'
    beq run_hopper
    cmp #'h'
    beq run_help
    cmp #'m'
    beq run_woz
    cmp #'r'
    beq run
    cmp #'x'
    beq run_xmodem
    cmp #'X'
    beq run_xmodem_highram

    lda #<prompt
    ldx #>prompt
    jsr acia_puts

    jmp loop

run_woz:
    jsr wozmon
    jmp loop
run_basic:
    lda #BASIC_BANK
    jmp rstfar
run_hopper:
    lda #HOPPER_BANK
    jmp rstfar
run_help:
    jsr cmd_help
    jmp loop
run_dos:
    jsr dos_init
    jmp loop
run:
    jsr cmd_run
    jmp loop
run_xmodem_highram:
    inc krn_ptr1
    lda #1
    sta rambankreg
    nop
    nop
    sta ram_bank
    sei
    jsr xmodem
    cli
    stz krn_ptr1
    stz rambankreg
    nop
    nop
    stz ram_bank
    jmp loop
run_xmodem:
    stz krn_ptr1
    sei
    jsr xmodem
    cli
    jmp loop

cmd_help:
    print strAnsiCLSHome
    print strWelcome
    newline
    lda #<strHelp
    sta ptr1
    lda #>strHelp
    sta ptr1 + 1
:   lda (ptr1)
    beq :+
    jsr acia_putc
    inc ptr1
    bne :-
    inc ptr1 +1
    bne :-
:   rts

cmd_run:
    jsr readline_init
    print strRunPrompt
    jsr readline
    lda inbuf
    beq :+
    ldy #0
    jsr read_address_from_input
    jmp (address)
:   jmp $0800

irq:
    pha
    phx
    phy

    bit F18A_REG
    bpl :+          ; not the F18A
    lda F18A_REG
    sta vdp+sVdp::status ; save the status register
    lda #$80
    sta vdp+sVdp::tick
    ; fall through
:   bit acia_status
    bpl :+          ; not the acia
:
    bit via_ifr
    bpl @return     ; not the via
@return:
    ply
    plx
    pla
    rti

.rodata
prompt: .byte $0a,$0d,"> ",$0
strWelcome: .asciiz "6502-Retro!!"
strHelp:
    .byte $0a,$0d
    .byte "USAGE INSTRUCTIONS", $0a,$0d
    .byte "==============================================================================",$0a,$0d
    .byte "h => help", $0a,$0d
    .byte "b => ehBasic", $0a,$0d
    .byte "d => DOS", $0a, $0d
    .byte "p => Hopper", $0a, $0d
    .byte "m => Wozmon", $0a,$0d
    .byte "r => Run from 0x800", $0a,$0d
    .byte "x => Xmodem receive", $0a,$0d
    .byte "X => Xmodem receive into extended memory", $0a, $0d
    .byte $0a,$0d,$0
strRunPrompt: 
    .byte $0a,$0d
    .byte "Enter address or ENTER to jump to 0x800: "
    .byte $0

.segment "VECTORS"
    .word $0000
    .word main
    .word irq
