.include "macros.inc"
.include "kern.inc"
.global strEndl, fat32_errno
.importzp ptr1

.export convert_error

.code

convert_error:
	print strEndl	        ; use the table of pointers to 
	lda #<error_ptrs	; find the pointer to the string we want to
	sta ptr1		; print.  Save into ptr1.
	lda #>error_ptrs
	sta ptr1 + 1
	lda fat32_errno		; add the error number x 2 to the pointer
	clc			; so that we are pointing at the corrent pointer.
	asl
	adc ptr1
	sta ptr1
	lda ptr1 + 1
	adc #0
	sta ptr1 + 1
	ldy #1			; now use indirect zeropage addressing to find the
	lda (ptr1),y		; the address of the string we want to print.
	tax			; high byte into X
	dey
	lda (ptr1),y		; low byte in A
	jsr acia_puts		; finally print it!
	print strEndl
	rts

.rodata

error_ptrs:
	.word strERRNO_OK
	.word strERRNO_READ
	.word strERRNO_WRITE
	.word strERRNO_ILLEGAL_FILENAME
	.word strERRNO_FILE_EXISTS
	.word strERRNO_FILE_NOT_FOUND
	.word strERRNO_FILE_READ_ONLY
	.word strERRNO_DIR_NOT_EMPTY
	.word strERRNO_NO_MEDIA
	.word strERRNO_NO_FS
	.word strERRNO_FS_INCONSISTENT
	.word strERRNO_WRITE_PROTECT_ON
	.word strERRNO_OUT_OF_RESOURCES

strERRNO_OK:			.asciiz "OK"
strERRNO_READ:			.asciiz "READ ERROR"
strERRNO_WRITE:			.asciiz "WRITE ERROR"
strERRNO_ILLEGAL_FILENAME:	.asciiz "ILLEGAL FILENAME"
strERRNO_FILE_EXISTS:		.asciiz "FILE EXISTS"
strERRNO_FILE_NOT_FOUND:	.asciiz "FILE NOT FOUND"
strERRNO_FILE_READ_ONLY:	.asciiz "FILE READ ONLY"
strERRNO_DIR_NOT_EMPTY:		.asciiz "DIRECTORY NOT EMPTY"
strERRNO_NO_MEDIA:		.asciiz "NO MEDIA"
strERRNO_NO_FS:			.asciiz "NO FILESYSTEM"
strERRNO_FS_INCONSISTENT:	.asciiz "FILESYSTEM INCONSISTENT"
strERRNO_WRITE_PROTECT_ON:	.asciiz "WRITE PROTECT ON"
strERRNO_OUT_OF_RESOURCES:	.asciiz "OUT OF RESOURCES"