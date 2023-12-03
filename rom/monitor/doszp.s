
; .export krn_ptr1, 
.exportzp bank_save
.exportzp fat32_bufptr, fat32_lfn_bufptr, fat32_ptr, fat32_ptr2
.exportzp ptr1, run_ptr, tmp1

.segment "DOSZP" : zeropage


; DOS / FAT32
; krn_ptr1:             ; already set up in kernzp
; 	.res 2
bank_save:
	.res 1

; FAT32
fat32_bufptr:
	.res 2 ; word - Internally used by FAT32 code
fat32_lfn_bufptr:
	.res 2 ; word - Internally used by FAT32 code
fat32_ptr:
	.res 2 ; word - Buffer pointer to various functions
fat32_ptr2:
	.res 2 ; word - Buffer pointer to various functions
sd_addr:
	.res 2 ; sdcard
; for dos itself.
ptr1:		.res 2
run_ptr:	.res 2
tmp1:		.res 1