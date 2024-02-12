; vim: ft=asm_ca65

; functions
.global sfs_init                        ; init the sdcard
.global sfs_mount                       ; read the volume ID and fill out volid struct
.global sfs_open_first_index_block      ; load the first directory index sector from disk
.global sfs_create                      ; create a new file.  Overwrites existing, or finds free.
.global sfs_find                        ; find a file and open it
.global sfs_read_next_index             ; use for enumerating through indexes.
.global sfs_write                       ; block write to an open file
.global sfs_read                        ; block read from an open file
.global sfs_delete                      ; soft delete - sets attribute to FF
.global sfs_format                      ; format the sdcard
.global sfs_open                        ; open a file for sequential access. A=1:read, A=2:write
.global sfs_close                       ; closes file opened for sequential access.
.global sfs_read_byte                   ; reads next byte in sequential access open file
.global sfs_write_byte                  ; writes next byte in A to to sequential access open file.

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
