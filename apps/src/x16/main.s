.include "bank.inc"
.include "zeropage.inc"
.include "kernal.inc"

.import _sd_init, _sd_readsector
.import _primm, _rambank
.globalzp sdptr
.global sd_sector_buffer, sd_lba

.macro BANKSTART
        pha
        lda     #DISKRAM
        sta     _rambankreg
        pla
.endmacro

.macro BANKEND
        pha
        lda     ram_bank
        sta     _rambankreg
        pla
.endmacro

.code
        jsr _primm
        .byte "Hello, World!", $0d, $0a, $0
        jsr     _sd_init
        BANKSTART
        stz     sd_lba + 0
        stz     sd_lba + 1
        stz     sd_lba + 2
        stz     sd_lba + 3
        
        lda     #<sd_sector_buffer
        sta     sdptr + 0
        lda     #>sd_sector_buffer
        sta     sdptr + 1
        jsr     _sd_readsector
        BANKEND
        rts

