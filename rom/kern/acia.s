; vim: ft=asm_ca65
.include "io.inc"
.import _vdp_console_out

.export acia_init, acia_getc, acia_getc_nw, acia_putc, acia_puts

.globalzp krn_ptr1

        .code

ACIA_PARITY_DISABLE          = %00000000
ACIA_ECHO_DISABLE            = %00000000
ACIA_TX_INT_DISABLE_RTS_LOW  = %00001000
ACIA_RX_INT_ENABLE           = %00000000
ACIA_RX_INT_DISABLE          = %00000010
ACIA_DTR_LOW                 = %00000001

.code
acia_init:
        lda #$00
        sta acia_status
        lda #(ACIA_PARITY_DISABLE | ACIA_ECHO_DISABLE | ACIA_TX_INT_DISABLE_RTS_LOW | ACIA_RX_INT_DISABLE | ACIA_DTR_LOW)
        sta acia_command
        lda #$10                   ; 16 x external clock which if running a 1.8432 MZ can, you get 115200 baud.
        ; lda #$1F                 ; This gives 19200 baud rate generator.
        sta acia_control
        rts

; void acia_put(char c)
; Send the character c to the serial terminal
; @in A (c) character to send
acia_putc:
        pha                         ; save char
@wait_txd_empty:
        lda     acia_status
        and     #$10
        beq     @wait_txd_empty
        pla                         ; restore char
        sta     acia_data
        rts

; char acia_getc()
; Wait until a character was received and return it
; @out A the received character
acia_getc:
@wait_rxd_full:
        lda     acia_status
        and     #$08
        beq     @wait_rxd_full
        lda     acia_data
        rts

; not C compliant, result is returned in carry.
acia_getc_nw:
        clc
        lda    acia_status
        and    #$08
        beq    @done
        lda    acia_data
        sec
@done:
        rts

; C Compliant
; void acia_puts(const char * s);
; string in XA
acia_puts:
        phy
        sta     krn_ptr1
        stx     krn_ptr1 + 1
        ldy     #0
:
        lda     (krn_ptr1),y
        beq     :+
        jsr     acia_putc
        iny
        jmp     :-
:
        ply
        rts
