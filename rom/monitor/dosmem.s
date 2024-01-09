.export index, volid, sfs_errno, sfs_bytes_rem

.global inbuf, inbuf_end, path, context, load_arg, FORMAT_BUF, address, length

.global shared_vars
.global shared_vars_len

.include "../sfs/structs.inc"

.segment "BSS"

shared_vars:

; API arguments and return data, shared from DOS into SFS
; but used primarily by SFS
index:          .tag sIndex         ; 
volid:          .tag sVolId         ; 
sfs_bytes_rem:  .word 0             ;
sfs_errno:      .byte 0             ;

inbuf:          .res 128
inbuf_end = *
path:		    .res 128
context:	    .byte 0
load_arg:	    .byte 0
address:        .word 0
length:         .word 0
FORMAT_BUF:     .res 16

shared_vars_len = * - shared_vars