.include "macros.inc"
.include "kern.inc"
.global strEndl, sfs_errno
.importzp ptr1

.export convert_error

.code

convert_error:
	print strEndl	        ; use the table of pointers to 
	lda #<error_ptrs	; find the pointer to the string we want to
	sta ptr1		; print.  Save into ptr1.
	lda #>error_ptrs
	sta ptr1 + 1
	lda sfs_errno		; add the error number x 2 to the pointer
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
        .addr strERRNO_OK
        .addr strERRNO_DISK_ERROR
        .addr strERRNO_SECTOR_READ_FAILED
        .addr strERRNO_SECTOR_WRITE_FAILED
        .addr strERRNO_END_OF_INDEX_ERROR
        .addr strERRNO_FILE_NOT_FOUND_ERROR
	.addr strERRNO_INVALID_MODE_ERROR

strERRNO_OK:                    .asciiz "OK"
strERRNO_DISK_ERROR:            .asciiz "Bad DISK error"
strERRNO_SECTOR_READ_FAILED:    .asciiz "Sector read failed"
strERRNO_SECTOR_WRITE_FAILED:   .asciiz "Sector write failed"
strERRNO_END_OF_INDEX_ERROR:    .asciiz "End of index sectors"
strERRNO_FILE_NOT_FOUND_ERROR:  .asciiz "File not found"
strERRNO_INVALID_MODE_ERROR:	.asciiz "Invalid file mode"