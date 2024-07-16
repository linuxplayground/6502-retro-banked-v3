; vim: ft=asm_ca65
.include "io.inc"
.include "sdcard.inc"
.include "kern.inc"
.include "sfs.inc"
.include "structs.inc"

.import sector_lba, sector_buffer, sector_buffer_end
.import match_name

.globalzp sfs_ptr, sfs_fn_ptr, sfs_data_ptr, sfs_tmp_ptr
.global sfs_errno, index, volid


.bss
current_idx_lba:           .dword 0
data_start:                .dword 0
sfs_read_first_index_flag: .byte 0
sfs_context:               .byte 0
sfs_tmp:                   .byte 0

.code

;------------------------------------------------------------------------
; reads a sector into sector buffer
; set sector_lba before calling this function
; returns C=1: OK, C=0: ERROR
;------------------------------------------------------------------------
sfs_readsector:
        jsr sdcard_read_sector
        bcs @ok
        lda #ERRNO_SECTOR_READ_FAILED
        sta sfs_errno
        clc
        rts
@ok:
        lda #ERRNO_OK
        sta sfs_errno
        sec
        rts

;------------------------------------------------------------------------
; writes a sector from  sector buffer to sdcard
; set sector_lba before calling this function
; returns C=1: OK, C=0: ERROR
;------------------------------------------------------------------------
sfs_writesector:
        jsr sdcard_write_sector
        bcs @ok
        lda #ERRNO_SECTOR_WRITE_FAILED
        sta sfs_errno
        clc
        rts
@ok:
        lda #ERRNO_OK
        sta sfs_errno
        sec
        rts

;------------------------------------------------------------------------
; initialise the library.
;------------------------------------------------------------------------
sfs_init:
        lda #<sector_buffer
        sta sfs_ptr
        lda #>sector_buffer
        sta sfs_ptr + 1
:
        lda #0                  ; clear out the dos data
        sta (sfs_ptr)
        clc
        lda sfs_ptr
        adc #1
        sta sfs_ptr
        lda sfs_ptr+1
        adc #0
        sta sfs_ptr+1
        cmp #$C0
        bne :-

        ; Run the SDCARD initialization 3 whole times.
        lda #3
        pha
@loop_init:
        jsr sdcard_init
        pla
        dec
        pha
        bne @loop_init
        pla
        rts

;------------------------------------------------------------------------
; read volume id block from sdcard, store data into the struct and validate
;------------------------------------------------------------------------
sfs_mount:
        stz sector_lba + 0
        stz sector_lba + 1
        stz sector_lba + 2
        stz sector_lba + 3
        jsr sdcard_read_sector
        bcc @baddisk
        ; validate signature
        lda sector_buffer + 510
        cmp #$BB
        bne @baddisk
        lda sector_buffer + 511
        cmp #$66
        bne @baddisk
        ; validate version
        lda sector_buffer + 8
        cmp #$30
        bne @baddisk
        lda sector_buffer + 9
        cmp #$30
        bne @baddisk
        lda sector_buffer + 10
        cmp #$30
        bne @baddisk
        lda sector_buffer + 11
        cmp #$31
        bne @baddisk

        ; save sVolumeId struct
        ldx #0
@1:
        lda sector_buffer, x
        sta volid, x
        inx
        cpx #24
        bne @1
        jmp @ok

@baddisk:
        lda #ERRNO_DISK_ERROR
        clc
        rts
@ok:
        jsr sfs_dump_volid
        lda #ERRNO_OK
        sec
        rts

;------------------------------------------------------------------------
; Loads the first index block into the sector buffer
;------------------------------------------------------------------------
sfs_open_first_index_block:
        lda volid + sVolId::index_start + 0
        sta current_idx_lba + 0
        lda volid + sVolId::index_start + 1
        sta current_idx_lba + 1
        lda volid + sVolId::index_start + 2
        sta current_idx_lba + 2
        lda volid + sVolId::index_start + 3
        sta current_idx_lba + 3
        ; fall through

;------------------------------------------------------------------------
; Loads the current index block into the sector buffer
;------------------------------------------------------------------------
sfs_load_index_block:
        lda current_idx_lba + 0
        sta sector_lba + 0
        lda current_idx_lba + 1
        sta sector_lba + 1
        lda current_idx_lba + 2
        sta sector_lba + 2
        lda current_idx_lba + 3
        sta sector_lba + 3
        jsr sdcard_read_sector
        bcc @error

        lda #<sector_buffer
        sta sfs_ptr
        lda #>sector_buffer
        sta sfs_ptr + 1
        stz sfs_read_first_index_flag   ; prepare to read first index
        
        lda #ERRNO_OK
        sta sfs_errno
                rts
@error:
        lda #ERRNO_SECTOR_READ_FAILED
        sta sfs_errno
                rts

;------------------------------------------------------------------------
; Reads the next index block into the sector buffer.  Checks against
; volid index_last to know if more to be read.
; C=0 End of index, C=1 success
;------------------------------------------------------------------------
sfs_open_next_index_block:
        clc
        lda current_idx_lba + 0
        adc #1
        sta current_idx_lba + 0

        beq @endofindex                 ; the index blocks go up to 00 00 00 FF
        cmp volid + sVolId::index_last + 0 ; only looking at the LSB of the 32bit value
        bcc @endofindex
@load:
        jmp sfs_load_index_block

@endofindex:
        lda #ERRNO_END_OF_INDEX_ERROR
        sta sfs_errno
        clc
        rts

;------------------------------------------------------------------------
; Increments sfs_ptr to next index and falls through to read it.
; OUTPUT: C = 0 End of indexes, C = 1 OK
;------------------------------------------------------------------------
sfs_read_next_index:
        lda sfs_read_first_index_flag
        bne @1
        inc sfs_read_first_index_flag
        bra sfs_read_index
@1:
        clc                     ; else add 32 to it and read.
        lda sfs_ptr
        adc #32
        sta sfs_ptr
        lda sfs_ptr + 1
        adc #0
        sta sfs_ptr + 1
        cmp #>sector_buffer_end
        bne sfs_read_index
        ; else
        jsr sfs_open_next_index_block
        bcs  sfs_read_next_index
        ; must have hit end of index
        clc
        rts

;------------------------------------------------------------------------
; Loads the current index pointed to by sfs_ptr into the index struct.
; OUTPUT: index is populated
;------------------------------------------------------------------------
sfs_read_index:
        ldy #0                  ; copy index into struct
@1:
        lda (sfs_ptr),y
        sta index,y
        iny
        cpy #32
        bne @1
        sec
        rts                             ; return ok

;------------------------------------------------------------------------
; searches through the index for a file that matches the name.
; search is case insensitve.
; INPUT: Filename in sfs_fn_ptr (null terminated)
; OUTPUT: C = 0 not found, C = 1 found
;------------------------------------------------------------------------
sfs_find:
        jsr sfs_open_first_index_block  ; sfs_ptr is pointing at start of buffer
        bcc @notfound
@1:
        jsr sfs_read_next_index         ; reads the next index - sets sfs_ptr to next
        bcc @notfound
        lda index + sIndex::attrib      ; if the attribute is empty, we must have
        beq @notfound                   ; reached the end of all indexes.
        jsr match_name
        bcs @found
        bra @1
@found:
        sec
        rts
@notfound:
        lda #ERRNO_FILE_NOT_FOUND_ERROR
        sta sfs_errno
        clc
        rts

;------------------------------------------------------------------------
; allocate new index block
; C=0 if no more blocks available, C=1 success
;------------------------------------------------------------------------
sfs_allocate_new_index_block:

        ; load volume id block
        stz sector_lba + 0
        stz sector_lba + 1
        stz sector_lba + 2
        stz sector_lba + 3
        jsr sdcard_read_sector

        ; increments index_last in volid and flush to disk.
        inc volid + sVolId::index_last
        beq @error ; no more index sectors left.

        ; copy updated volume ID to the sector buffer
        ldx #0
@1:
        lda volid,x
        sta sector_buffer,x
        inx
        cpx #32         ; volid is only 24 bytes long but I write 32 anyway.
        bne @1

        jsr sdcard_write_sector ; flush
        ; now load the current index sector again.
        lda current_idx_lba + 0
        sta sector_lba + 0
        lda current_idx_lba + 1
        sta sector_lba + 1
        lda current_idx_lba + 2
        sta sector_lba + 2
        lda current_idx_lba + 3
        sta sector_lba + 3
        jsr sdcard_read_sector

        lda #<sector_buffer
        sta sfs_ptr
        lda #>sector_buffer
        sta sfs_ptr + 1
        stz sfs_read_first_index_flag   ; prepare to read first index
        sec
        rts
@error:
        lda #ERRNO_END_OF_INDEX_ERROR
        sta sfs_errno
        clc
        rts

;------------------------------------------------------------------------
; searches through index sectors for a free index.
;------------------------------------------------------------------------
sfs_find_free_index:
        jsr sfs_open_first_index_block
@1:
        jsr sfs_read_next_index
        bcc @endofindex
        lda index + sIndex::attrib      ; attribute 0x00 = not used
        beq @found                      ; attribute 0xFF = deleted / free
        cmp #$FF
        beq @found
        bra @1
@found:
        rts
@endofindex:
        ; before failing for real, see if we can't allocate another index block
        jsr sfs_allocate_new_index_block
        bcc @endofindex2
        bra @1
@endofindex2:
        lda #ERRNO_END_OF_INDEX_ERROR
        sta sfs_errno
        clc
        rts

;------------------------------------------------------------------------
; calls find to see if file exists.  If it does, load index struct and
; return success.
; sfs_fn_ptr points to null terminated file name to find.
; returns with index populated and sfs_ptr pointing to index location
; in sector_buffer
;------------------------------------------------------------------------
sfs_create:
        jsr sfs_find    ; search for the file in the index
        bcs @copy_filename ; always overwrite.
@find_free:
        jsr sfs_find_free_index 
@copy_filename:
        ldy #0
@1:
        lda (sfs_fn_ptr),y
        beq @2
        sta index + sIndex::filename,y
        iny
        cpy #21
        beq @3
        bra @1
@2:
        lda #0
        sta index + sIndex::filename, y
        iny
        lda #$20
@2a:
        sta index + sIndex::filename,y
        iny
        cpy #21
        bne @2a
@3:
        lda #$40
        sta index + sIndex::attrib
@exit:
        rts

;------------------------------------------------------------------------
; first save open index back to disk then
; write sfs_bytes_rem bytes to disk starting at sfs_data_ptr
;------------------------------------------------------------------------
sfs_write:
        ; update the index and flush it to disk.
        ; save size into index
        lda sfs_bytes_rem + 0
        sta index + sIndex::size + 0
        lda sfs_bytes_rem + 1
        sta index + sIndex::size + 1

        ; copy index into sector buffer at sfs_ptr
        ldy #0
@1:
        lda index,y
        sta (sfs_ptr),y
        iny
        cpy #32
        bne @1

        ; write buffer to sdcard
        lda index + sIndex::index_lba + 0
        sta sector_lba + 0
        lda index + sIndex::index_lba + 1
        sta sector_lba + 1
        lda index + sIndex::index_lba + 2
        sta sector_lba + 2
        lda index + sIndex::index_lba + 3
        sta sector_lba + 3
        jsr sdcard_write_sector
        bcs @2
        lda #ERRNO_DISK_ERROR
        sta sfs_errno
        clc
        rts
@2:
        ldx #0
        stx ram_bank
        stx rambankreg
        nop
        lda sfs_data_ptr + 1
        cmp #$A0
        bne @3a
        ldx #1
        stx ram_bank

        ; set up sector LBA
        lda index + sIndex::start + 0
        sta sector_lba + 0
        lda index + sIndex::start + 1
        sta sector_lba + 1
        lda index + sIndex::start + 2
        sta sector_lba + 2
        lda index + sIndex::start + 3
        sta sector_lba + 3

        ; copy bytes_rem data from data_ptr to sector buffer.
        ; flush each time the buffer is full until bytes_rem = 0
@3:
        lda #<sector_buffer     ; use sfs_ptr to track place in buffer
        sta sfs_ptr
        lda #>sector_buffer
        sta sfs_ptr + 1

@3a:
        ldx ram_bank
        stx rambankreg
        nop
        lda (sfs_data_ptr)      ; save a byte
        stz rambankreg
        nop
        sta (sfs_ptr)

        lda sfs_bytes_rem       ; decrement bytes_rem until zero
        bne @3b
        lda sfs_bytes_rem + 1
        beq @5                  ; done
        dec sfs_bytes_rem + 1
@3b:    dec sfs_bytes_rem

        inc sfs_data_ptr        ; increment data pointer
        bne @3c
        inc sfs_data_ptr + 1
        lda sfs_data_ptr + 1
        cmp #$C0
        bne @3c
        inc ram_bank
        lda #$A0
        sta sfs_data_ptr + 1

@3c:    clc
        lda sfs_ptr
        adc #1
        sta sfs_ptr
        lda sfs_ptr + 1
        adc #0
        sta sfs_ptr + 1
        cmp #>sector_buffer_end ; if end of buffer - flush to disk.
        beq @4
        bra @3a

@4:
        jsr debug_sector_lba
        jsr sdcard_write_sector
        bcc @error
        clc
        lda sector_lba + 0
        adc #1
        sta sector_lba + 0
        lda sector_lba + 1
        adc #0
        sta sector_lba + 1
        lda sector_lba + 2
        adc #0
        sta sector_lba + 2
        lda sector_lba + 3
        adc #0
        sta sector_lba + 3
        jmp @3
@5:
        inc sfs_ptr             ; fill rest of last sector with 0x00
        bne @5a
        inc sfs_ptr + 1
        lda sfs_ptr + 1
        cmp #>sector_buffer_end
        beq @5b
@5a:    lda #0
        sta (sfs_ptr)
        bra @5
@5b:
        jsr debug_sector_lba
        jsr sdcard_write_sector ; one last write
        rts
@error:
        lda #ERRNO_DISK_ERROR
        sta sfs_errno
        clc
        rts

;------------------------------------------------------------------------
; read file from open file into sfs_data_ptr.
; First call find with filename in sfs_fn_ptr to open the file.
;------------------------------------------------------------------------
sfs_read:
        ; get file size
        lda index + sIndex::size + 0
        sta sfs_bytes_rem + 0
        lda index + sIndex::size + 1
        sta sfs_bytes_rem + 1

        ; set up start lba
        lda index + sIndex::start + 0
        sta sector_lba + 0
        lda index + sIndex::start + 1
        sta sector_lba + 1
        lda index + sIndex::start + 2
        sta sector_lba + 2
        lda index + sIndex::start + 3
        sta sector_lba + 3

        ldx #0
        stx ram_bank
        stx rambankreg
        nop
        lda sfs_data_ptr + 1
        cmp #$A0
        bne @loop
        ldx #1
        stx ram_bank
@loop:
        ; load from disk into sector_buffer, then copy sector buffer into dataptr
        ; until bytes remaining = 0
        jsr sdcard_read_sector
        lda #<sector_buffer
        sta sfs_ptr
        lda #>sector_buffer
        sta sfs_ptr + 1
@1:
        stz rambankreg
        nop
        lda (sfs_ptr)
        ldx ram_bank
        stx rambankreg 
        nop
        sta (sfs_data_ptr)
        stz rambankreg
        nop
        lda sfs_bytes_rem       ; decrement bytes_rem until zero
        bne @1b
        lda sfs_bytes_rem + 1
        beq @done                ; done
        dec sfs_bytes_rem + 1
@1b:    dec sfs_bytes_rem

        inc sfs_data_ptr        ; inc data pointer
        bne @1c
        inc sfs_data_ptr + 1
        lda sfs_data_ptr + 1
        cmp #$C0
        bne @1c
        inc ram_bank
        lda #$A0
        sta sfs_data_ptr + 1
@1c:
        inc sfs_ptr             ; increment buffer pointer
        bne @1
        inc sfs_ptr + 1
        lda sfs_ptr + 1
        cmp #>sector_buffer_end ; check for end of buffer
        bne @1

        clc                      ; need to load the next sector
        lda sector_lba + 0
        adc #1
        sta sector_lba + 0
        lda sector_lba + 1
        adc #0
        sta sector_lba + 1
        lda sector_lba + 2
        adc #0
        sta sector_lba + 2
        lda sector_lba + 3
        adc #0
        sta sector_lba + 3
        jmp @loop
@done:
        rts

;------------------------------------------------------------------------
; Delete an open file.
; First call find with filename in sfs_fn_ptr to open the file.
;------------------------------------------------------------------------
sfs_delete:
        lda #$FF
        sta index + sIndex::attrib        ; Attrib = FF means deleted file.
        
        ldy #0
@1:
        lda index,y
        sta (sfs_ptr),y
        iny
        cpy #32
        bne @1

        lda index + sIndex::index_lba + 0
        sta sector_lba + 0
        lda index + sIndex::index_lba + 1
        sta sector_lba + 1
        lda index + sIndex::index_lba + 2
        sta sector_lba + 2
        lda index + sIndex::index_lba + 3
        sta sector_lba + 3
        jmp sdcard_write_sector

;------------------------------------------------------------------------
; Open a file.
; INPUTS:
;       A=1, Open for read
;       A=2, Open for write
;       sfs_fn_ptr, null terminated filename
; Opens and already open file for sequential read or write access
;------------------------------------------------------------------------
sfs_open:
        cmp #2  ; mode must be <= 2
        beq @writemode
        bcs @error
        ; read mode
        sta sfs_context
        ; get file size
        lda index + sIndex::size + 0
        sta sfs_bytes_rem + 0
        lda index + sIndex::size + 1
        sta sfs_bytes_rem + 1
        bra @setuplba
@writemode:
        sta sfs_context
        stz sfs_bytes_rem
        stz sfs_bytes_rem + 1
        ; sfs_ptr currently points to index location in index sector.
        ; need to save it for close later on.
        lda sfs_ptr
        sta sfs_tmp_ptr
        lda sfs_ptr + 1
        sta sfs_tmp_ptr + 1
@setuplba:
        ; set up start lba
        lda index + sIndex::start + 0
        sta sector_lba + 0
        lda index + sIndex::start + 1
        sta sector_lba + 1
        lda index + sIndex::start + 2
        sta sector_lba + 2
        lda index + sIndex::start + 3
        sta sector_lba + 3
        
        jsr debug_sector_lba

        jsr sdcard_read_sector
        bcc @diskreaderror
        lda #<sector_buffer
        sta sfs_ptr
        lda #>sector_buffer
        sta sfs_ptr + 1

        sec
        rts
@diskreaderror:
        lda #ERRNO_SECTOR_READ_FAILED
        sta sfs_errno
        clc
        rts
@error:
        lda #ERRNO_INVALID_MODE_ERROR
        sta sfs_errno
        clc
        rts

;------------------------------------------------------------------------
; Close an open file.
; Clears sfs_context.  
; If context was created for writing:
;       - Final buffer is written
;       - index is updated and flushed to disk.
;------------------------------------------------------------------------
sfs_close:
        lda sfs_context
        cmp #$01
        beq @reset_context  ; if read mode just clear the context.
        ;; here is where we need to write final buffer 
@fill:
        clc
        lda sfs_ptr
        adc #1
        sta sfs_ptr
        lda sfs_ptr + 1
        adc #0
        sta sfs_ptr + 1
        cmp #>sector_buffer_end
        beq @2
        lda #0
        sta (sfs_ptr)
        bra @fill
@2:
        jsr debug_sector_lba
        jsr sdcard_write_sector ; one last write
        bcc @error
                        ; fall through

@write_index:
        lda sfs_bytes_rem
        sta index + sIndex::size
        lda sfs_bytes_rem + 1
        sta index + sIndex::size + 1

        ; load the index sector
        lda index + sIndex::index_lba + 0
        sta sector_lba + 0
        lda index + sIndex::index_lba + 1
        sta sector_lba + 1
        lda index + sIndex::index_lba + 2
        sta sector_lba + 2
        lda index + sIndex::index_lba + 3
        sta sector_lba + 3
        jsr debug_sector_lba
        jsr sdcard_read_sector
        bcc @readerror
        ; copy index into buffer
        ldy #0
@3:
        lda index,y
        sta (sfs_tmp_ptr),y
        iny
        cpy #32
        bne @3
        jsr debug_sector_lba
        jsr sdcard_write_sector
        bcc @error
        ; fall through to close 
@reset_context:
        stz sfs_context
        sec
        rts
@readerror:
        lda #ERRNO_SECTOR_READ_FAILED
        sta sfs_errno
        clc
        rts
@error:
        lda #ERRNO_SECTOR_WRITE_FAILED
        sta sfs_errno
        clc
        rts

;------------------------------------------------------------------------
; Read Byte
; Reads the next byte in an open file.  If the end of the file is reached
; return C=0 and final byte in A.
; Open a file with sfs_open before starting.
;------------------------------------------------------------------------
sfs_read_byte:
        ; check context
        lda sfs_context
        cmp #$01
        bne @modeerror
        ; read and stash current byte
        lda (sfs_ptr)
        sta sfs_tmp
        ; we increment the sfs_ptr
        clc
        lda sfs_ptr
        adc #1
        sta sfs_ptr
        lda sfs_ptr + 1
        adc #0
        sta sfs_ptr + 1
        cmp #>sector_buffer_end
        bne @checkeof

        clc
        lda sector_lba + 0
        adc #1
        sta sector_lba + 0
        lda sector_lba + 1
        adc #0
        sta sector_lba + 1
        lda sector_lba + 2
        adc #0
        sta sector_lba + 2
        lda sector_lba + 3
        adc #0
        sta sector_lba + 3
        
        jsr sdcard_read_sector
        bcc @diskreaderror

        lda #<sector_buffer     ; reset buffer pointer
        sta sfs_ptr
        lda #>sector_buffer
        sta sfs_ptr + 1

@checkeof:
        ; check for eof
        lda sfs_bytes_rem
        bne :+
        dec sfs_bytes_rem + 1
:       dec sfs_bytes_rem

        lda sfs_bytes_rem + 0
        ora sfs_bytes_rem + 1
        bne :+
        jmp @eof
:
        lda sfs_tmp
        sec
        rts
@eof:
        lda #ERRNO_OK
        sta sfs_errno
        lda sfs_tmp
        clc
        rts
@modeerror:
        lda #ERRNO_INVALID_MODE_ERROR
        sta sfs_errno
        clc
        rts
@diskreaderror:
        lda #ERRNO_SECTOR_READ_FAILED
        sta sfs_errno
        clc
        rts

;------------------------------------------------------------------------
; Write Byte
; Writes a byte to the next sequential position in the open file buffer.
; If the end of the buffer is reached, then flush the buffer, set up the
; the next LBA and reset the buffer pointer.
; Index is written on close.
; return C=0.
; Open a file with sfs_open before starting.
;------------------------------------------------------------------------
sfs_write_byte:
        pha             ; stash received byte
        ; check context
        lda sfs_context
        cmp #2          ; 02 for write mode
        bne @modeerror
        pla             ; restore received byte
        pha             ; stash it again
        sta (sfs_ptr)   ; save to buffer

        ; now increment sfs_bytes_rem
        clc
        lda sfs_bytes_rem
        adc #1
        sta sfs_bytes_rem
        lda sfs_bytes_rem + 1
        adc #0
        sta sfs_bytes_rem + 1

        ; now increment ptr and check for buffer overflow
        clc
        lda sfs_ptr
        adc #1
        sta sfs_ptr
        lda sfs_ptr + 1
        adc #0
        sta sfs_ptr + 1
        cmp #>sector_buffer_end
        bne @nobufferoverflow
        ; flush the buffer to disk
        jsr sdcard_write_sector
        ; increment next sector
        clc
        lda sector_lba + 0
        adc #1
        sta sector_lba + 0
        lda sector_lba + 1
        adc #0
        sta sector_lba + 1
        lda sector_lba + 2
        adc #0
        sta sector_lba + 2
        lda sector_lba + 3
        adc #0
        sta sector_lba + 3
        ; reset buffer pointer
        lda #<sector_buffer
        sta sfs_ptr
        lda #>sector_buffer
        sta sfs_ptr + 1
@nobufferoverflow:
        pla             ; return requested char
        sec             ; success
        rts
@modeerror:
        lda #ERRNO_INVALID_MODE_ERROR
        sta sfs_errno
        pla             ; return requested char
        clc
        rts
@diskerror:
        lda #ERRNO_SECTOR_WRITE_FAILED
        sta sfs_errno
        pla             ; return requested char
        clc
        rts

;------------------------------------------------------------------------
; Print out the current SDCARD LBA Address
;------------------------------------------------------------------------
debug_sector_lba:
.if 1
        rts
.endif
        jsr primm
        .byte 10,13,"SECTOR_LBA: ",0
        lda sector_lba + 3
        jsr prbyte
        lda sector_lba + 2
        jsr prbyte
        lda sector_lba + 1
        jsr prbyte
        lda sector_lba + 0
        jsr prbyte
        rts

;------------------------------------------------------------------------
; print out details of the volume id
;------------------------------------------------------------------------
sfs_dump_volid:
.if 1
        rts
.endif
        jsr primm
        .byte 10, 13, "VOLUME ID:   ",0
        ldx #0
@1:
        lda volid + sVolId::id,x
        jsr acia_putc
        inx
        cpx #8
        bne @1

        jsr primm
        .byte 10, 13, "VERSION:     ",0
        ldx #0
@2:
        lda volid + sVolId::version, x
        jsr acia_putc
        inx
        cpx #4
        bne @2

        jsr primm
        .byte 10, 13, "INDEX START: ",0
        lda volid + sVolId::index_start + 3
        jsr prbyte
        lda volid + sVolId::index_start + 2
        jsr prbyte
        lda volid + sVolId::index_start + 1
        jsr prbyte
        lda volid + sVolId::index_start + 0
        jsr prbyte

        jsr primm
        .byte 10, 13, "INDEX LAST:  ",0
        lda volid + sVolId::index_last + 3
        jsr prbyte
        lda volid + sVolId::index_last + 2
        jsr prbyte
        lda volid + sVolId::index_last + 1
        jsr prbyte
        lda volid + sVolId::index_last + 0
        jsr prbyte

        jsr primm
        .byte 10, 13, "DATA START:  ",0
        lda volid + sVolId::data_start + 3
        jsr prbyte
        lda volid + sVolId::data_start + 2
        jsr prbyte
        lda volid + sVolId::data_start + 1
        jsr prbyte
        lda volid + sVolId::data_start + 0
        jsr prbyte
        jsr primm
        .byte 10,13,0
        rts
