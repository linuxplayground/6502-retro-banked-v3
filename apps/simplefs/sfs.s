.include "sdcard.inc"
.include "kern.inc"
.include "sfs.inc"
.include "structs.inc"
.MACPACK longbranch

.import sector_lba, sector_buffer, sector_buffer_end
.import match_name

.export primm



; zeropage addresses used
sfs_ptr         = $C0
;                 $C1
sfs_fn_ptr      = $C2
;                 $C3
sfs_data_ptr    = $C4
;                 $C5
sfs_tmp_ptr     = $C6
;                 $C7

ERRNO_OK                        = $00
ERRNO_DISK_ERROR                = $01
ERRNO_SECTOR_READ_FAILED        = $02
ERRNO_SECTOR_WRITE_FAILED       = $03
ERRNO_END_OF_INDEX_ERROR        = $04
ERRNO_FILE_NOT_FOUND_ERROR      = $05

.bss
sfs_errno:              .byte 0
current_idx_lba:        .dword 0
index:                  .tag sIndex
volid:                  .tag sVolId
sfs_bytes_rem:          .word 0
data_start:             .dword 0
sfs_read_first_index_flag: .byte 0

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
        lda volid
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
        bcs  sfs_read_index
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
; INPUT: Filename in sfs_fn_ptr (null terminated)
;               search is case insenstive
; OUTPUT: C = 0 not found, C = 1 found
;------------------------------------------------------------------------
sfs_find:
        jsr sfs_open_first_index_block  ; sfs_ptr is pointing at start of buffer
        bcc @notfound
@1:
        jsr sfs_read_next_index         ; reads the next index - sets sfs_ptr to next
@1a:
        jsr match_name
        bcs @found
@1b:
        jsr sfs_read_next_index
        bcc @notfound
        jsr match_name
        bcs @found
        bra @1b
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
        ; jsr sfs_dump_volid
        jsr sdcard_write_sector ; flush
        ; now load the sector again.
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
; searches through index for a free index.
; when it finds one, it adds the data start location into the index
; and updates it on disk.
;------------------------------------------------------------------------
sfs_find_free_index:
        jsr sfs_open_first_index_block
@1:
        jsr sfs_read_next_index
        bcc @endofindex
        lda index + sIndex::filename + 0        ; if first char is 0x00 then it's free
        beq @found
        bra @1
@found:
        rts
@endofindex:
        ; before failing for real, see if we can't allocate another index block
        jsr sfs_allocate_new_index_block
        bcc @endofindex2
        jsr sfs_read_next_index
        lda index + sIndex::filename + 0
        beq @found
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
; returns with index populated and sfs_tmp_ptr pointing to index location
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
        lda #$20
        iny
@2a:
        sta index + sIndex::filename,y
        iny
        cpy #21
        bne @2a
@3:
        lda #$40
        sta index + sIndex::attrib
@exit:
        ; check if our index is greater than the volume last index
        rts

;------------------------------------------------------------------------
; write sfs_bytes_rem bytes from sfs_data_ptr into open file.
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
        lda (sfs_data_ptr)      ; save a byte
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

@3c:    inc sfs_ptr             ; increment buffer pointer
        bne @3a
        inc sfs_ptr+1
        lda sfs_ptr+1
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

@loop:
        ; load from disk into sector_buffer, then copy sector buffer into dataptr
        ; until bytes remaining = 0
        jsr sdcard_read_sector
        lda #<sector_buffer
        sta sfs_ptr
        lda #>sector_buffer
        sta sfs_ptr + 1
@1:
        lda (sfs_ptr)
        sta (sfs_data_ptr)
        
        lda sfs_bytes_rem       ; decrement bytes_rem until zero
        bne @1b
        lda sfs_bytes_rem + 1
        beq @done                ; done
        dec sfs_bytes_rem + 1
@1b:    dec sfs_bytes_rem
        
        inc sfs_data_ptr        ; inc data pointer
        bne @1c
        inc sfs_data_ptr + 1
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

debug_sector_lba:
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


;------------------------------------------------------------------------
; Print immediate
;------------------------------------------------------------------------
primm:
      pla
      sta   krn_ptr1
      pla
      sta   krn_ptr1+1
      bra   @primm3
@primm2:
      jsr   acia_putc
@primm3:
      inc   krn_ptr1
      bne   @primm4
      inc   krn_ptr1+1
@primm4:
      lda   (krn_ptr1)
      bne   @primm2
      lda   krn_ptr1+1
      pha
      lda   krn_ptr1
      pha
      rts