
; .export krn_ptr1, 
.exportzp bank_save
.exportzp sfs_ptr, sfs_fn_ptr, sfs_data_ptr, sfs_tmp_ptr
.exportzp ptr1, run_ptr, tmp1

.segment "DOSZP" : zeropage


; DOS / FAT32
; krn_ptr1:             ; already set up in kernzp
; 	.res 2
bank_save:
	.res 1

; SFS
sfs_ptr:
	.res 2 ; 
sfs_fn_ptr:
	.res 2 ; 
sfs_data_ptr:
	.res 2 ; 
sfs_tmp_ptr:
	.res 2 ;

; for dos itself.
ptr1:		.res 2
run_ptr:	.res 2
tmp1:		.res 1
