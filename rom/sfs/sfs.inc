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
.global sfs_format
.global sfs_open
.global sfs_close
.global sfs_read_byte

; data
.global index
.global sfs_bytes_rem, sfs_errno
.global char_temp

; zeropage
.globalzp sfs_ptr, sfs_fn_ptr, sfs_data_ptr

ERRNO_OK                        = $00
ERRNO_DISK_ERROR                = $01
ERRNO_SECTOR_READ_FAILED        = $02
ERRNO_SECTOR_WRITE_FAILED       = $03
ERRNO_END_OF_INDEX_ERROR        = $04
ERRNO_FILE_NOT_FOUND_ERROR      = $05
ERRNO_INVALID_MODE_ERROR        = $06