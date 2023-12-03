.export fat32_size
.export fat32_errno
.export fat32_dirent
.export fat32_readonly
.export skip_mask
.export shared_vars
.export shared_vars_len

.export inbuf, inbuf_end, path, context, load_arg, FORMAT_BUF, address, length

.include "../fat32/lib.inc"

.segment "BSS"

shared_vars:

; API arguments and return data, shared from DOS into FAT32
; but used primarily by FAT32
fat32_dirent:        .tag dirent   ; Buffer containing decoded directory entry
fat32_size:          .res 4        ; Used for fat32_read, fat32_write, fat32_get_offset, fat32_get_free_space
fat32_errno:         .byte 0       ; Last error
fat32_readonly:      .byte 0       ; User-accessible read-only flag

skip_mask:
      .byte 0

inbuf:          .res 128
inbuf_end = *
path:		    .res 128
context:	    .byte 0
load_arg:	    .byte 0
address:        .word 0
length:         .word 0
FORMAT_BUF:     .res 16

shared_vars_len = * - shared_vars