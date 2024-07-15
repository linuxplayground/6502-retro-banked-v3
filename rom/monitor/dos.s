; vim: ft=asm_ca65
.include "kern.inc"
.include "macros.inc"
.include "io.inc"
.include "../sfs/structs.inc"
.include "../sfs/sfs.inc"

.export read_address_from_input

SD_CS           = %00000010
SD_SCK          = %00000001
SD_MOSI         = %10000000

.global strEndl
.importzp ptr1, run_ptr, tmp1

.import index, volid, sfs_errno, sfs_bytes_rem

.import convert_error
.import readline, readline_init
.import BinToBcd, FORMAT_BUF
.import inbuf, inbuf_end, load_arg, path, address, length
.import to_lower
.export dos_init, strAnsiCLSHome, dos_bdir

.code
dos_init:
	jsr readline_init

	jsr sfs_init

	print strAnsiCLSHome
	newline
	print strWelcome

input_loop:
	jsr readline
	ldy #0
	lda inbuf,y
	jsr to_lower
	cmp #'h'
	beq @jmp_help
	cmp #'d'
	beq @jmp_dir
	cmp #'f'
	beq @jmp_format
	cmp #'l'
	beq @jmp_load
	cmp #'s'
	beq @jmp_save
	cmp #'t'
	beq @jmp_cat
	cmp #'r'
	beq @jmp_run
	cmp #'q'
	beq @jmp_quit
	cmp #'u'
	beq @jmp_unlink
	print strSyntaxError
	jmp input_loop
@jmp_help:
	jsr cmd_help
	jmp input_loop
@jmp_dir:
	jsr cmd_dir
	jmp input_loop
@jmp_format:
	jsr cmd_format
	jmp input_loop
@jmp_load:
	jsr cmd_load
	jmp input_loop
@jmp_save:
	jsr cmd_save
	jmp input_loop
@jmp_cat:
	jsr cmd_cat
	jmp input_loop
@jmp_run:
	jsr cmd_run
	jmp input_loop
@jmp_quit:
	jmp end
@jmp_unlink:
	jsr cmd_unlink
	jmp input_loop

cmd_help:
	print strAnsiCLSHome
	print strWelcome
	newline
	lda #<strHelp
	sta ptr1
	lda #>strHelp
	sta ptr1 + 1
:	lda (ptr1)
	beq :+
	jsr acia_putc
	inc ptr1
	bne :-
	inc ptr1 +1
	bne :-
:	rts

; open_dir path
; lists directory
; closes directory
cmd_dir:
	jsr sfs_mount

	; y is at first character
	jsr consume_to_end_of_next_space
	jsr read_path_from_input

	newline

	lda path + 1			; is / the whole path
	bne dos_bdir
	lda #'['
	jsr acia_putc
	ldx #0
:	lda volid + sVolId::id,x
	jsr acia_putc
	inx
	cpx #8
	bne :-
	lda #']'
	jsr acia_putc

dos_bdir:			; entry point when called from basic
	newline
@1:
	jsr sfs_open_first_index_block
@2:
	jsr sfs_read_next_index
	bcc @end
	lda index + sIndex::attrib
	beq @end
	cmp #$FF
	beq @2
@3:
	; print file size in hex
	lda index + sIndex::size + 1
	sta sfs_bytes_rem + 1
	lda index + sIndex::size + 0
	sta sfs_bytes_rem + 0
	lda #2
	jsr BinToBcd
	jsr print_dec_buf
	lda #' '
	jsr acia_putc
@4:
	; print file name
        ldx #0
:       lda index + sIndex::filename,x
        jsr acia_putc
        inx
        cpx #21
        bne :-

	newline
	bra @2
@not_found:
	jmp convert_error
@end:
	rts

cmd_load:
	; y is at first character
	jsr consume_to_end_of_next_space
	jsr read_path_from_input
	iny
	jsr read_address_from_input
	; print some information
	newline
	lda #<strLoading
	ldx #>strLoading
	jsr acia_puts
	lda #<path
	ldx #>path
	jsr acia_puts
	lda #<strOx
	ldx #>strOx
	jsr acia_puts
	lda address + 1
	jsr prbyte
	lda address
	jsr prbyte
	newline
	; find file
	lda #<path
	sta sfs_fn_ptr
	lda #>path
	sta sfs_fn_ptr + 1
	lda address
	sta sfs_data_ptr
	lda address + 1
	sta sfs_data_ptr + 1
	jsr sfs_find
	bcc @error
	jsr sfs_read
	bcc @error
	rts
@error:
	jmp convert_error

cmd_save:
	jsr consume_to_end_of_next_space
	jsr read_path_from_input
	iny
	jsr read_address_from_input
	iny
	jsr read_length_from_input
	; print out some information
	lda #<strSaving
	ldx #>strSaving
	jsr acia_puts
	; path
	lda #<path
	ldx #>path
	jsr acia_puts
	; size
	lda #' '
	jsr acia_putc
	lda #'['
	jsr acia_putc
	lda length + 1
	jsr prbyte
	lda length
	jsr prbyte
	lda #<strBytes
	ldx #>strBytes
	jsr acia_puts
	; from address
	lda #<strFrom
	ldx #>strFrom
	jsr acia_puts

	lda address + 1
	jsr prbyte
	lda address
	jsr prbyte
	; create file
	lda #<path
	sta sfs_fn_ptr + 0
	lda #>path
	sta sfs_fn_ptr + 1
	jsr sfs_create
	bcc @error
	; write the file
	lda address
	sta sfs_data_ptr
	lda address + 1
	sta sfs_data_ptr + 1
	lda length
	sta sfs_bytes_rem
	lda length + 1
	sta sfs_bytes_rem + 1
	jsr sfs_write
	bcc @error
	rts
@error:
	jmp convert_error

cmd_unlink:
	jsr consume_to_end_of_next_space
	jsr read_path_from_input
	lda #<path
	sta sfs_fn_ptr
	lda #>path
	sta sfs_fn_ptr + 1
	jsr sfs_find
	bcc @error
	jsr sfs_delete
	bcc @error
	rts
@error:
	jmp convert_error

cmd_cat:
	jsr consume_to_end_of_next_space
	jsr read_path_from_input
	lda #<path
	sta sfs_fn_ptr
	lda #>path
	sta sfs_fn_ptr + 1
	jsr sfs_find
	bcc @error
    lda #1
    jsr sfs_open
    bcc @error

    jsr primm
    .byte 10, 13, 0

@1:
    jsr sfs_read_byte
    bcc @close
    jsr acia_putc
    cmp #$0a
    bne :+
    lda #$0d
    jsr acia_putc
:
	bra @1
@close:
    lda sfs_errno
    cmp #ERRNO_OK
    beq @done
    jmp @error
@done:
    jsr primm
    .byte 10, 13, "END OF FILE",0
    jsr sfs_close
    bcc @error
    rts
@error:
    jmp convert_error

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

cmd_format:
	lda #<strAreYouSure
	ldx #>strAreYouSure
	jsr acia_puts
	jsr acia_getc
	cmp #'Y'
	bne @end
	jsr sfs_format
@end:
	rts

consume_to_end_of_next_space:
	lda inbuf,y
	beq :++
	cmp #' '
	beq :+
	iny
	bne consume_to_end_of_next_space
	; now use up all the spaces
:	iny
	lda inbuf,y
	beq :+
	cmp #' '
	beq :-
	cmp #$09		; tab
	beq :-
: 	rts

read_path_from_input:
	; y is start of path
	; keep going until space or $0
	ldx #0
:	lda inbuf,y
	beq :+
	cmp #' '
	beq :+
	cmp #$09		; tab
	beq :+
	sta path,x
	inx
	iny
	bne :-
:	lda #0			; zero terminate the path.
	sta path,x
	; jsr consume_to_end_of_next_space
	rts

; fills address with data address data from inbuf
; input: Y = start of address data in inbuf
; outputs: address has binary value of address
read_address_from_input:
	; y is at start of address data
	lda inbuf,y
	iny
	ldx inbuf,y
	iny
	jsr hex_str_to_byte
	sta address + 1
	lda inbuf,y
	iny
	ldx inbuf,y
	iny
	jsr hex_str_to_byte
	sta address
	rts

; fills length with data address data from inbuf
; input: Y = start of address data in inbuf
; outputs: address has binary value of address
read_length_from_input:
	; y is at start of address data
	lda inbuf,y
	iny
	ldx inbuf,y
	iny
	jsr hex_str_to_byte
	sta length + 1
	lda inbuf,y
	iny
	ldx inbuf,y
	iny
	jsr hex_str_to_byte
	sta length
	rts


; prints zero terminated binary encoded decimal buffer.
print_dec_buf:
	sta load_arg
	sec
	sbc #2
	bcs @gt_2
	lda load_arg
	sec
	sbc #1
	bcs @gt_1
	ldx #6
	bra @print_sp
@gt_1:
	ldx #4
	bra @print_sp
@gt_2:
	ldx #2
@print_sp:	
	lda #' '
:
	jsr acia_putc
	dex
	bne :-

	ldx load_arg
:
	lda FORMAT_BUF-1,x
	jsr prbyte
	dex
	bne :-
	rts

end:
        lda #(SD_CS|SD_MOSI)        	; deselect sdcard
        sta via_porta
	rts

; A = high nibble, X = low nibble
; result in A
hex_str_to_byte:
        jsr @asc_hex_to_bin          	; convert to number - result is in A
        asl                             ; shift to high nibble
        asl
        asl
        asl
        sta tmp1                        ; and store
        txa                             ; get the low nibble character
        jsr @asc_hex_to_bin             ; convert to number - result is in A
        ora tmp1                        ; OR with previous result
        rts

@asc_hex_to_bin:                        ; assumes ASCII char val is in A
        sec
        sbc #$30                        ; subtract $30 - this is good for 0-9
        cmp #10                         ; is value more than 10?
        bcc @asc_hex_to_bin_end         ; if not, we're okay
        sbc #$07                        ; otherwise subtract another $07 for A-F
@asc_hex_to_bin_end:
        rts                             ; value is returned in A

.rodata
strWelcome:  	 	.asciiz "6502 RetroDOS"
strSyntaxError:		.byte $0a, $0d, "Syntax Error", $0a, $0d, $0
strLoading:		.asciiz "Loading ... "
strSaving:		.asciiz "Saving ..."
strFrom:		.asciiz " from 0x"
strBytes: 		.asciiz "] bytes "
strOK:			.byte " - OK", $0a, $0d, $0
strDirPrefix:		.asciiz " [DIR] "
strAreYouSure:		.asciiz "Are you sure? <Y|*> "
strEndl:     	 	.byte $0a, $0d, $0
strAnsiCLSHome:  	.byte $0D,$0A, $1b, "[2J", $1b, "[H", $0
str800:			.asciiz "800"
strOx:			.asciiz " into 0x"
strSpace:		.asciiz "  "

strHelp:
	.byte $0a,$0d
	.byte "USAGE INSTRUCTIONS", $0a,$0d
	.byte "==============================================================================",$0a,$0d
	.byte "h => help", $0a,$0d
	.byte "d => dir - mount and list all files.", $0a,$0d
	.byte "f => Format", $0a, $0d
	.byte "l => load <filename> <start_address>", $0a, $0d
	.byte "s => save <filename> <start_address> <size in bytes>", $0a,$0d
	.byte "t => cat <filename> - prints all printable chars from file until eof.", $0a,$0d
	.byte "q => quit",$0a,$0d
	.byte "u => unlink",$0a,$0d,$0a,$0d,$0
strRunPrompt: 
    .byte $0a,$0d
    .byte "Enter address or ENTER to jump to 0x800: "
    .byte $0


