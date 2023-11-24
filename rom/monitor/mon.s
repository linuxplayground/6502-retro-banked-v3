.include "io.inc"
.include "banks.inc"
.import acia_init, acia_getc, acia_getc_nw, acia_putc, acia_puts
.import jsrfar, init_ram
.import wozmon, xmodem

.globalzp ram_bank, rom_bank
.code
main:
        sei
        cld
        ldx     #$ff
        txs

        jsr init_ram
        
        jsr acia_init

        lda MONITOR_BANK
        sta rom_bank
        sta ram_bank
        sta rambankreg

        cli

        ; start
        lda #<banner
        ldx #>banner
        jsr acia_puts

loop:
        lda #<prompt
        ldx #>prompt
        jsr acia_puts

        jsr acia_getc
        jsr acia_putc
        cmp #'b'
        beq run_basic
        cmp #'m'
        beq run_woz
        cmp #'r'
        beq run
        cmp #'x'
        beq run_xmodem

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
run:
        jsr $0800
        jmp loop
run_xmodem:
        sei
        jsr xmodem
        cli
        jmp loop

.rodata
banner: .byte $0a,$0d,"RETROMON-V3",$a,$d,$0
prompt: .byte $0a,$0d,"> ",$0

.segment "VECTORS"
        .word $0000
        .word main
        .word $0000
