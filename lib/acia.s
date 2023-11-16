.include "zeropage.inc"

.import __ACIA_START__
.export _acia_init
.export _acia_putc
.export _acia_getc
.export _acia_getc_nw
.export _acia_puts
.export ACIA_STATUS

ACIA_DATA    = __ACIA_START__ + $00
ACIA_STATUS  = __ACIA_START__ + $01
ACIA_COMMAND = __ACIA_START__ + $02
ACIA_CONTROL = __ACIA_START__ + $03

        .code


ACIA_PARITY_DISABLE          = %00000000
ACIA_ECHO_DISABLE            = %00000000
ACIA_TX_INT_DISABLE_RTS_LOW  = %00001000
ACIA_RX_INT_ENABLE           = %00000000
ACIA_RX_INT_DISABLE          = %00000010
ACIA_DTR_LOW                 = %00000001

.code
_acia_init:
        lda #$00
        sta ACIA_STATUS
        lda #(ACIA_PARITY_DISABLE | ACIA_ECHO_DISABLE | ACIA_TX_INT_DISABLE_RTS_LOW | ACIA_RX_INT_ENABLE | ACIA_DTR_LOW)
        sta ACIA_COMMAND
        lda #$10
        sta ACIA_CONTROL
        rts

; void acia_put(char c)
; Send the character c to the serial terminal
; @in A (c) character to send
_acia_putc:
        pha                         ; save char
@wait_txd_empty:
        lda     ACIA_STATUS
        and     #$10
        beq     @wait_txd_empty
        pla                         ; restore char
        sta     ACIA_DATA
        rts

; char acia_getc()
; Wait until a character was received and return it
; @out A the received character
_acia_getc:
@wait_rxd_full:
        lda     ACIA_STATUS
        and     #$08
        beq     @wait_rxd_full
        lda     ACIA_DATA
        rts

; not C compliant, result is returned in carry.
_acia_getc_nw:
        clc
        lda    ACIA_STATUS
        and    #$08
        beq    @done
        lda    ACIA_DATA
        sec
@done:
        rts

; C Compliant
; void acia_puts(const char * s);
; string in XA
_acia_puts:
        phy
        sta     ptr1
        stx     ptr1 + 1
        ldy     #0
:
        lda     (ptr1),y
        beq     :+
        jsr     _acia_putc
        iny
        jmp     :-
:
        ply
        rts
