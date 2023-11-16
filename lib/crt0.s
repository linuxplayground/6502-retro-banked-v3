.include "zeropage.inc"
.export _init
.import _main, __LORAM_START__, __LORAM_SIZE__

.export __STARTUP__ : absolute = 1

.import zerobss, initlib

.segment  "STARTUP"

; ---------------------------------------------------------------------------
; A little light 6502 housekeeping

_init:

; ---------------------------------------------------------------------------
; Set cc65 argument stack pointer

    LDA     #<(__LORAM_START__ + __LORAM_SIZE__)
    STA     sp
    LDA     #>(__LORAM_START__ + __LORAM_SIZE__)
    STA     sp+1

    ; Clear the BSS section of memory
    jsr zerobss

    ; Run constructors
    jsr initlib

    ; Jump to main()
    jsr _main

    rts
