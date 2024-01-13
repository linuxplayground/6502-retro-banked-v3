.include "kern.inc"
.include "lib/lib.inc"
.include "io.inc"

.import getline, hex_str_to_byte
.import __BANK_START__

BS              = $08
CR              = $0D
ESC             = $1B
CTRLC           = $03

tmp1 = $F0
ptr1 = $F2
ptr2 = $F4

.exportzp tmp1, ptr1, ptr2

.macro print_nl
        lda #<strEndl
        ldx #>strEndl
        jsr acia_puts
.endmacro

.macro print addr
        lda #<addr
        ldx #>addr
        jsr acia_puts
.endmacro

.macro setptr src, dst
        lda #<dst
        sta src
        lda #>dst
        sta src + 1
.endmacro


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
        jsr     acia_putc
        lda     #$0D
        jsr     acia_putc

        lda     ptr1+1
        jsr     prbyte
        lda     ptr1
        jsr     prbyte
        lda     #':'
        jsr     acia_putc
        lda     #' '
        jsr     acia_putc
        ldy     #0
@dump_1l_lp:
        lda     (ptr1), y
        pha
        jsr     prbyte
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
        jsr     acia_putc
        lda     #'-'
        jsr     acia_putc
@gap1:        
        lda     #' '
        jsr     acia_putc
@gap2:
        iny
        cpy     #16
        bne     @dump_1l_lp
        lda     #' '
        jsr     acia_putc
        ldy     #0
@dump_1l_lp2:
        lda     ASCIISTR,y
        jsr     acia_putc
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
        jsr     acia_getc
        cmp     #$20
        beq     @next_line
        rts
@next_line:
        add16_val       ptr1, ptr1, 16
        jmp     @dump_one_line

help:
        lda     #<strHelp
        ldx     #>strHelp
        jsr     acia_puts
        rts
bank:
        ldx     STDIN_IDX
        inx
        lda     STDIN_BUF,x
        pha
        inx
        lda     STDIN_BUF,x     ; low nibble in X
        tax
        stx     STDIN_IDX
        pla
        jsr     hex_str_to_byte ; convert to byte
        sta     rambankreg
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
                .byte           "B XX          - Set bank to XX (with leading zeros)",$0a,$0d
                .byte           "H             - Dispaly this help.",$0a,$0d
                .byte           "Q             - Quit",$0
strEndl:        .byte $0a, $0d, $0