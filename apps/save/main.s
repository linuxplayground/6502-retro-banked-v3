.include "fat32.inc"
.include "banks.inc"
.include "io.inc"
.include "fat32zp.inc"
.include "kern.inc"

.global fat32_size, krn_ptr1, fat32_errno

.macro fat32_call func
	jsr jsrfar
	.word func
	.byte FAT32_BANK
.endmacro

.code
	lda #0
	sta stage		; 0

        fat32_call sdcard_init
	inc stage		; 1

        fat32_call fat32_init
	inc stage		; 2

        jsr alloc_context
	bcc @error

	inc stage		; 3
	lda #<strName
	sta fat32_ptr
	lda #>strName
	sta fat32_ptr + 1
	sec				; delete file if already exists
	fat32_call fat32_create
	bcc @error

	inc stage		; 4
	lda #<$800
	sta fat32_ptr
	lda #>$800
	sta fat32_ptr + 1
	lda #0
	sta fat32_size
	lda #1
	sta fat32_size + 1
	lda #0
	sta krn_ptr1
	fat32_call fat32_write
	bcc @error
	inc stage		; 5	
	fat32_call fat32_close
	bcc @error
	inc stage		; 6
	jsr free_context
	rts
@error:
	jsr convert_error
	jsr free_context
	jsr beep
	rts

alloc_context:
	lda #0
	fat32_call fat32_alloc_context
	bcs @alloc_ok
	jsr convert_error
	clc
	rts
@alloc_ok:
	sta context
	fat32_call fat32_set_context
	sec
	rts

free_context:
	lda context
	fat32_call fat32_free_context
	rts

convert_error:
	lda stage
	jsr prbyte
	lda #'-'
	jsr acia_putc
	lda fat32_errno
	jsr prbyte
	rts

jsrfar:
.include "jsrfar.inc"

context: .byte 0
stage: .byte 0
.rodata
strName: .asciiz "/hellord.txt"
