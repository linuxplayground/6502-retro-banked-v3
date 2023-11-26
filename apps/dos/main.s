.export fat32_size
.export fat32_errno
.export fat32_dirent
.export fat32_readonly
.export skip_mask
.export shared_vars
.export shared_vars_len

.import sdcard_init, fat32_init, fat32_alloc_context, fat32_free_context, fat32_open, fat32_read
.import fat32_set_context, fat32_read_byte

.include "../fat32/lib.inc"
.include "kern.inc"
.include "banks.inc"

.segment "DOSBSS"

shared_vars:

; API arguments and return data, shared from DOS into FAT32
; but used primarily by FAT32
fat32_dirent:        .tag dirent   ; Buffer containing decoded directory entry
fat32_size:          .res 4        ; Used for fat32_read, fat32_write, fat32_get_offset, fat32_get_free_space
fat32_errno:         .byte 0       ; Last error
fat32_readonly:      .byte 0       ; User-accessible read-only flag

skip_mask:
      .byte 0
context:
      .byte 0

shared_vars_len = * - shared_vars

.macro newline
	pha
	phx
	lda #<strEndl
	ldx #>strEndl
	jsr acia_puts
	plx
	pla
.endmacro

.macro print addr
	pha
	phx
	lda #<addr
	ldx #>addr
	jsr acia_puts
	plx
	pla
.endmacro

.code
	ldx #<shared_vars_len
:	stz shared_vars+$ff,x
	dex
	bne :-

	ldx #0
:	stz shared_vars,x
	inx
	bne :-

	newline
	print strWelcome
	
	jsr sdcard_init
	bcc error
	jsr fat32_init
	bcc error
	lda #0
	jsr fat32_alloc_context
	bcc error
	sta context
	jsr fat32_set_context

	lda #<strFilename
	sta fat32_ptr
	lda #>strFilename
	sta fat32_ptr + 1
	jsr fat32_open
	bcc error

	lda fat32_dirent + dirent::size
	sta fat32_size
	lda fat32_dirent + dirent::size + 1
	sta fat32_size + 1
	stz fat32_ptr
	lda #$80
	sta fat32_ptr + 1
	
	newline

@loop:	jsr fat32_read_byte
	bcc end
	jsr acia_putc
	jmp @loop

end:
	lda context
	jsr fat32_free_context
	rts

error:
	newline
	lda fat32_errno
	jsr prbyte
	rts

.rodata
strWelcome:  .byte "Welcome to DOS",$0
strEndl:     .byte $0a, $0d, $0
strFilename: .byte "/TEST.TXT",$0