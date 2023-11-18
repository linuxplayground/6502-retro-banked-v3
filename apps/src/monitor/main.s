.include "kernal.inc"
.include "bank.inc"
.include "zeropage.inc"
.include "lib.inc"

.import getline, hex_str_to_byte
.import _rambank

BS              = $08
CR              = $0D
ESC             = $1B
CTRLC           = $03

.code
        print_nl
        print   strBanner
input:
        print_nl
        print   strPrompt
        setptr  ptr1, STDIN_BUF
        setptr  ptr2, NARGS
        lda     #64
        jsr     getline

; reads in the first word on STDIN_BUF and finds if it's a command we support and
; then dispatches to that routine
process:
        ldx     #1
        stx     STDIN_IDX
        lda     STDIN_BUF

        cmp     #'B'
        beq     @bank
        cmp     #'D'
        beq     @dump
        cmp     #'H'
        beq     @help
        cmp     #'T'
        beq     @test
        cmp     #'Q'
        beq     @quit
        print   strSyntaxError
        print_nl
        jmp     input
@bank:
        jsr     bank
        jmp     input
@dump:
        jsr     dump
        jmp     input
@help:
        jsr     help
        jmp     input
@test:
        jsr     test
        jmp     input
@quit:
        rts

dump:
        stz     tmp1
        print_nl
        jsr     read_address
        lda     STDIN_ADDR + 1
        sta     ptr1 + 1
        lda     STDIN_ADDR + 0
        sta     ptr1 + 0
        lda     NARGS
        cmp     #1
        beq     @dump_one_line
        jsr     read_address
        lda     STDIN_ADDR + 1
        sta     ptr2+1
        lda     STDIN_ADDR + 0
        sta     ptr2+0
        lda     #$01
        sta     tmp1
        jmp     @dump_multiple_lines
@dump_one_line:
        lda     #$0A
        jsr     _cputc
        lda     #$0D
        jsr     _cputc

        lda     ptr1+1
        jsr     _prbyte
        lda     ptr1
        jsr     _prbyte
        lda     #':'
        jsr     _cputc
        lda     #' '
        jsr     _cputc
        ldy     #0
@dump_1l_lp:
        lda     (ptr1), y
        pha
        jsr     _prbyte
        pla
        pha
        clc
        adc     #($ff-'z')
        adc     #('z' - $19)
        bcc     @dot
        pla
        sta     ASCIISTR, y
        bra     @gap
@dot:
        pla
        lda     #'.'
        sta     ASCIISTR,y
@gap:
        cpy     #8
        bne     @gap1
        lda     #' '
        jsr     _cputc
        lda     #'-'
        jsr     _cputc
@gap1:        
        lda     #' '
        jsr     _cputc
@gap2:
        iny
        cpy     #16
        bne     @dump_1l_lp
        lda     #' '
        jsr     _cputc
        ldy     #0
@dump_1l_lp2:
        lda     ASCIISTR,y
        jsr     _cputc
        iny
        cpy     #16
        bne     @dump_1l_lp2
        lda     tmp1
        beq     @check_next_line
@return:
        rts
@dump_multiple_lines:
        jsr     @dump_one_line
        add16_val       ptr1, ptr1, 16
        cmp16_lt        ptr1, ptr2, @dump_multiple_lines
        rts
@check_next_line:
        jsr     _cgetc
        cmp     #$20
        beq     @next_line
        rts
@next_line:
        add16_val       ptr1, ptr1, 16
        jmp     @dump_one_line

help:
        lda     #<strHelp
        ldx     #>strHelp
        jsr     _cputs
        rts
bank:
        ldx     STDIN_IDX
        inx
        lda     STDIN_BUF,x
        sta     _rambankreg
        rts
; test all the memory
test:
        ; start with page 10
        jsr     _primm
        .byte $0a,$0d, "LOW RAM page 10 to page 9E", $0a,$0d,$00
        lda     #0
        ldx     #$10
:
        stx     $FE
        stx     $FF
        stx     $FD
        txa
        sta     ($FE)
        lda     ($FE)
        cmp     $FD
        bne     @fail
        inx
        cpx     #$9F
        bne     :-
        jsr     _primm
        .byte "LOW RAM TESTS PASSED", $0a,$0d
        .byte "HI RAM", $0a,$0d,$00
        bra    @hiram
@fail:
        jsr     _primm
        .byte "Error at page ",$0
        txa
        jsr     _prbyte
        lda     #SYSTEMRAM
        sta     _rambankreg
        rts
@hiram:
        lda     #$42
        sta     $2345                   ; store a fixed value at an arbitrary address
        ldy     #$00                    ; and check it during bank tests to make sure that it does not change.
:
        phy
        phx
        jsr     _primm
        .byte $0a,$0d,"Testing RAM BANK: ",$00
        tya
        jsr     _prbyte
        plx
        ply
        sty     _rambankreg
        ldx     #$A0
:
        stx     $FF
        lda     #$80
        sta     $FE
        lda     #$AA
        sta     ($FE)
        lda     ($FE)
        cmp     #$AA
        bne     @fail
        lda     $2345
        cmp     #$42
        bne     @fail
        inx
        cpx     #$C0
        bne     :-
        iny
        cpy     #64
        bne     :--
        jsr     _primm
        .byte $0a,$0d,"All Banks tested ok.",$0a, $0d, $0 
        lda     #SYSTEMRAM
        sta     _rambankreg
        rts

        

; read an address.  Assumed to be directly after the filename.
; address will be intered in as HEX and then converted to a binary value
; and stored in STDIN_ADDR and STDIN_ADDR + 1
read_address:
        ldx     STDIN_IDX
        inx
        lda     STDIN_BUF,x             ; HIGH NIBBLE
        pha     ; push to stack
        inx     
        stx     STDIN_IDX               ; save index
        lda     STDIN_BUF,x             ; LOW NIBBLE
        tax
        pla     ; pull from stack
        jsr     hex_str_to_byte
        sta     STDIN_ADDR + 1          ; save into 16 bit field

        ldx     STDIN_IDX               ; restore index
        inx
        lda     STDIN_BUF,x             ; HIGH NIBBLE
        pha     ; push to stack
        inx     
        stx     STDIN_IDX               ; save index
        lda     STDIN_BUF,x             ; LOW NIBBLE
        inx
        stx     STDIN_IDX
        tax
        pla     ; pull from stack
        jsr     hex_str_to_byte
        sta     STDIN_ADDR              ; save into 16 bit field
        rts

STDIN_BUF:      .res 64
STDIN_ADDR:     .res 2
STDIN_IDX:      .res 1
NARGS:          .res 1
ASCIISTR:       .res 16


.rodata
strBanner:      .asciiz "Extended Monitor"
strPrompt:      .asciiz "M> "
strSyntaxError: .asciiz "Syntax error"
strHelp:        .byte $0a, $0d, "D XXXX [YYYY] - Show memory starting at XXXX and optionally ending at YYYY", $0a,$0d
                .byte           "B X           - Set bank to X",$0a,$0d
                .byte           "H             - Dispaly this help.",$0a,$0d
                .byte           "T             - Perform a rudimentary RAM test.",$0a,$0d
                .byte           "Q             - Quit",$0