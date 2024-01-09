; functions
.global sfs_init
.global sfs_mount
.global sfs_open_first_index_block
.global sfs_create
.global sfs_find                        ; use this to open a file
.global sfs_read_next_index             ; use for enumerating through indexes.
.global sfs_write
.global sfs_read
.global sfs_delete

.global sfs_dump_volid

.global sfs_format

; data
.global index
.global sfs_bytes_rem, sfs_errno
.global char_temp

; zeropage
.globalzp sfs_ptr, sfs_fn_ptr, sfs_data_ptr
