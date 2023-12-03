.include "../fat32/regs.inc"
.include "kern.inc"
.include "fat32.inc"
.include "banks.inc"
.include "macros.inc"

SD_CS           = %00010000
SD_MOSI         = %00000100

.global strEndl
.importzp ptr1, run_ptr, tmp1

.import fat32_dirent, fat32_errno, fat32_size
.import convert_error
.import readline, readline_init
.import BinToBcd, FORMAT_BUF
.import inbuf, inbuf_end, context, load_arg, path, address, length
.import jsrfar

.export dos_init, strAnsiCLSHome

.code
dos_init:
	jsr readline_init

	fat32_call sdcard_init
	fat32_call fat32_init

	print strAnsiCLSHome
	newline
	print strWelcome

	jsr alloc_context

; read a command and dispatch based on first char.
; h => help
; d => dir </path/to/directory> (also changes to that directory)
; l => load </path/to/file> [0|1|2] - Default is 1
;               0 = Load to 0x800 (file does not contain load address)
;               1 = Load to address defined in first 2 bytes of file.
;               2 = Load to 0x800 (ignores address in first 2 bytes of file)
; s => save </path/to/file> <start_address> <size in bytes>
; c => cat </path/to/textfile> - prints all printable chars from file until eof.
; q => quit
input_loop:
	jsr readline
	ldy #0
	lda inbuf,y
	jsr to_lower
	cmp #'h'
	beq @jmp_help
	cmp #'c'
	beq @jmp_dir
	cmp #'d'
	beq @jmp_dir
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
	; y is at first character
	jsr consume_to_end_of_next_space
	jsr read_path_from_input

	jsr alloc_context

	newline

	lda path + 1			; is / the whole path
	bne @1
	fat32_call fat32_get_vollabel
	lda #'['
	jsr acia_putc
	lda #<fat32_dirent + dirent::name
	ldx #>fat32_dirent + dirent::name
	jsr acia_puts
	lda #']'
	jsr acia_putc

	newline
@1:
	lda #<path
	sta fat32_ptr
	lda #>path
	sta fat32_ptr + 1
	fat32_call fat32_chdir
	stz fat32_ptr
	stz fat32_ptr + 1
	fat32_call fat32_open_dir
	bcc @not_found
@2:
	fat32_call fat32_read_dirent
	bcc @end
	lda fat32_dirent + dirent::name
	cmp #$E5
	beq @2
	; test attribute
	lda fat32_dirent + dirent::attributes
	cmp #$12
	beq @2
	cmp #$22
	beq @2

	cmp #$30
	beq :+
	cmp #$10		; is directory
	bne @3
:	lda #<strDirPrefix
	ldx #>strDirPrefix
	jsr acia_puts
	jmp @4
@3:
	; print file size in hex
	lda fat32_dirent + dirent::size + 1
	sta fat32_size + 1
	lda fat32_dirent + dirent::size + 0
	sta fat32_size + 0
	lda #2
	jsr BinToBcd
	jsr print_dec_buf
	lda #' '
	jsr acia_putc
@4:
	; print file or dir name
	lda #<fat32_dirent + dirent::name
	ldx #>fat32_dirent + dirent::name
	jsr acia_puts

	newline
	bra @2
@not_found:
	jsr convert_error
@end:
	newline
	lda #<strFreeSpacePrefix
	ldx #>strFreeSpacePrefix
	jsr acia_puts
	stz fat32_dirent + dirent::size
	stz fat32_dirent + dirent::size + 1
	stz fat32_dirent + dirent::size + 2
	stz fat32_dirent + dirent::size + 3
	fat32_call fat32_get_free_space
	jsr get_units
	pha
	lda #2
	jsr BinToBcd
	jsr print_dec_buf
	lda #' '
	jsr acia_putc
	pla
	jsr acia_putc


	fat32_call fat32_close
	jsr free_context
	rts

; checks if a file
; XXX This logic needs refining.
; depending on the arguments, loads to the address:
; 0 - given by first byte of the file
; 1 - 800 straight direct ignoring potential address header in file
; 2 - default - 800 ignoring the value of the first 2 bytes
cmd_load:
	; y is at first character
	jsr consume_to_end_of_next_space
	jsr read_path_from_input
	; get the argument to load (read_path already consumes to the end of next space.)
	iny
	lda inbuf,y
	sta load_arg

	jsr alloc_context

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

	lda #<path
	sta fat32_ptr
	lda #>path
	sta fat32_ptr + 1
	fat32_call fat32_open
	bcc @not_found1
	lda fat32_dirent + dirent::attributes
	cmp #$20
	bne @not_found

	lda load_arg
	cmp #'0'
	beq @0
	cmp #'1'
	beq @1
	bra @2		; default is 2.
@not_found1:
	jsr convert_error
	jmp @end
@0:
	lda #<str800
	ldx #>str800
	jsr acia_puts

	stz fat32_ptr
	stz run_ptr
	lda #$08
	sta fat32_ptr + 1
	sta run_ptr + 1
	bra @load
@1:
	; try to find the first 2 bytes of the file...
	fat32_call fat32_read_byte
	sta fat32_ptr
	sta run_ptr
	fat32_call fat32_read_byte
	sta fat32_ptr + 1
	sta run_ptr + 1
	jsr prbyte
	lda fat32_ptr
	jsr prbyte

	lda #2
	sta fat32_size
	stz fat32_size + 1
	stz fat32_size + 2
	stz fat32_size + 3
	fat32_call fat32_seek

	bra @load
@2:
	lda #<str800
	ldx #>str800
	jsr acia_puts

	lda #$fe
	sta fat32_ptr
	lda #$07
	sta fat32_ptr + 1
	stz run_ptr
	lda #$08
	sta run_ptr + 1
	bra @load
@not_found:
	jsr convert_error
	jmp @end
@load:
	; load the size.  Read will not read past end of file.
	lda fat32_dirent + dirent::size
	sta fat32_size
	lda fat32_dirent + dirent::size + 1
	sta fat32_size + 1

	; read the rest of the file.
	stz krn_ptr1		; do not write to single location.
	fat32_call fat32_read
	bcc @not_found
@loaded:
	newline
	lda #<strOK
	ldx #>strOK
	jsr acia_puts
@end:
	fat32_call fat32_close
	jsr free_context
	rts

; save memory to the SDCARD
; save filename.ext $start_addr $size (values in hex)
;
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
	sta fat32_ptr
	lda #>path
	sta fat32_ptr + 1
	lda #$80
	rol			; Carry = 1 overwrite file if exists
	jsr alloc_context
	fat32_call fat32_create
	bcc @end
	lda #'.'
	jsr acia_putc	; file created

	; save file
	lda address
	sta fat32_ptr
	lda address + 1
	sta fat32_ptr + 1
	lda length
	sta fat32_size
	lda length + 1
	sta fat32_size + 1
	lda #0
	sta krn_ptr1   ; fat32_read examines it to determine which copy routine to use.
	fat32_call fat32_write
	lda #'.'
	jsr acia_putc	; file created
	jsr convert_error
@end:
	fat32_call fat32_close
	jsr convert_error
	jsr free_context
	rts

cmd_unlink:
	; y is at first character
	jsr consume_to_end_of_next_space
	jsr read_path_from_input
	jsr alloc_context
	lda #<path
	sta fat32_ptr
	lda #>path
	sta fat32_ptr + 1
	fat32_call fat32_delete
	jsr free_context
	jsr convert_error
	rts

cmd_cat:
	; y is at first character
	jsr consume_to_end_of_next_space
	jsr read_path_from_input

	jsr alloc_context

	newline
	lda #<strLoading
	ldx #>strLoading
	jsr acia_puts
	lda #<path
	ldx #>path
	jsr acia_puts

	lda #<path
	sta fat32_ptr
	lda #>path
	sta fat32_ptr + 1
	fat32_call fat32_open
	bcc @not_found
	newline
	lda fat32_dirent + dirent::attributes
	cmp #$20
	bne @not_found
@1:
	fat32_call fat32_read_byte
	bcc @end
	jsr acia_putc
	cmp #$0A
	bne :+
	lda #$0D
	jsr acia_putc
: 	bra @1
	bra @end
@not_found:
	jmp convert_error
@end:
	fat32_call fat32_close
	jsr free_context
	rts

cmd_run:
	jmp (run_ptr)



;; SUPPORTING FUNCTIONS
to_lower:
	; Lower case character?
	cmp #'A'
	bcc @done
	cmp #'Z'+1
	bcs @done

	; Make lowercase
	ora #$20
@done:	rts

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

alloc_context:
	fat32_call fat32_alloc_context
	sta context
	fat32_call fat32_set_context
	rts

free_context:
	lda context
	fat32_call fat32_free_context
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

get_units:
	lda fat32_size + 2
	ora fat32_size + 3
	bne @not_kb
	lda #'K'
	bra @done_units
@not_kb:
	jsr shr10
	lda fat32_size + 2
	bne @not_mb
	lda #'M'
	bra @done_units
@not_mb:
	jsr shr10
	lda #'G'
@done_units:
	rts

shr10:
	; >> 8
	lda fat32_size + 1
	sta fat32_size + 0
	lda fat32_size + 2
	sta fat32_size + 1
	lda fat32_size + 3
	sta fat32_size + 2
	stz fat32_size + 3

	; >> 2
	lsr fat32_size + 2
	ror fat32_size + 1
	ror fat32_size + 0
	lsr fat32_size + 2
	ror fat32_size + 1
	ror fat32_size + 0

	rts

end:
	fat32_call fat32_close
	jsr free_context
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
strEndl:     	 	.byte $0a, $0d, $0
strAnsiCLSHome:  	.byte $0D,$0A, $1b, "[2J", $1b, "[H", $0
str800:			.asciiz "800"
strOx:			.asciiz " into 0x"
strFreeSpacePrefix:	.asciiz " Free Space: "
strFreeSpaceSuffix:	.asciiz " KB"
strSpace:		.asciiz "  "

strHelp:
	.byte $0a,$0d
	.byte "USAGE INSTRUCTIONS", $0a,$0d
	.byte "==============================================================================",$0a,$0d
	.byte "h => help", $0a,$0d
	.byte "d => dir </path/to/directory> (also changes to that directory)", $0a,$0d
	.byte "c => As above - muscle memory needs cd to work", $0a, $0d
	.byte "l => load </path/to/file> [0|1|2] - Default is 1", $0a,$0d
	.byte "    0 = Load to 0x800 (file does not contain load address)", $0a,$0d
	.byte "    1 = Load to address defined in first 2 bytes of file.", $0a,$0d
	.byte "    2 = Load to 0x800 (ignores address in first 2 bytes of file)", $0a,$0d
	.byte "s => save </path/to/file> <start_address> <size in bytes>", $0a,$0d
	.byte "t => cat </path/to/textfile> - prints all printable chars from file until eof.", $0a,$0d
	.byte "q => quit",$0a,$0d
	.byte "u => unlink",$0a,$0d,$0a,$0d,$0
