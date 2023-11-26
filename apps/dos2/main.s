.include "../fat32/regs.inc"
.include "kern.inc"
.include "fat32.inc"
.include "banks.inc"

.importzp ram_bank, rom_bank
.import fat32_dirent, fat32_errno, fat32_size

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

.macro fat32_call func
	jsr jsrfar
	.word func
	.byte FAT32_BANK
.endmacro

ptr1 = $f0

.code
main:
	newline
	print strWelcome
	
	fat32_call sdcard_init
	bcc @error
	fat32_call fat32_init
	bcc @error
	lda #0
	fat32_call fat32_alloc_context
	bcc @error
	sta context
	fat32_call fat32_set_context

	lda #<strFilename
	sta fat32_ptr
	lda #>strFilename
	sta fat32_ptr + 1
	fat32_call fat32_open
	bcc @error
	
	newline
	jmp @loop
@error:
	jmp error
@loop:	fat32_call fat32_read_byte
	bcc load
	jsr acia_putc
	cmp #$0a
	bne @loop
	lda #$0d
	jsr acia_putc
	jmp @loop

load:
; save a file from disk to ram.  First 2 bytes are location to save to.
	; open the file.

	lda context
	fat32_call fat32_alloc_context
	sta context
	fat32_call fat32_set_context

	lda #<strMonFilename
	sta fat32_ptr
	lda #>strMonFilename
	sta fat32_ptr + 1
	fat32_call fat32_open
	bcc error

	; read low byte of load address
	fat32_call fat32_read_byte
	bcc error
	sta ptr1
	; read high byte of load address
	fat32_call fat32_read_byte
	bcc error
	sta ptr1 + 1
@savelp:
	fat32_call fat32_read_byte
	bcc end
	sta (ptr1)
	clc
	lda ptr1
	adc #1
	sta ptr1
	lda ptr1+1
	adc #0
	sta ptr1+1
	jmp @savelp

end:
	lda context
	fat32_call fat32_free_context
	rts

error:
	newline
	lda fat32_errno
	jsr prbyte
	rts

context:
	.byte 0
jsrfar:
	.include "../../rom/inc/jsrfar.inc"

.rodata
strWelcome:  .byte "Welcome to DOS",$0
strEndl:     .byte $0a, $0d, $0
strRoot: .byte "/",$0
strFilename: .byte "/subdir/long_file_name.txt",$0
strMonFilename: .byte "/mon.bin",$0
