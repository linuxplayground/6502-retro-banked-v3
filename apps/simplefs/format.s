.include "sfs.inc"
.include "kern.inc"
.include "sdcard.inc"
.include "structs.inc"

.global sector_buffer, sector_buffer_end, sector_lba
.import primm

.bss
data_start: .dword 0

.code
;------------------------------------------------------------------------
; Setup Populate Volume ID Block
; Zero out Index Block
;
; VOLUME ID
; 0-7     VOLUME ID ASCII                 = "SFS.DISK"
; 8-11    VERSION                         = "0001"
; 12-15   LBA OF START OF INDEX           = 00 00 00 80
; 16-19   LBA OF LAST USED INDEX BLOCK    = 00 00 00 80
; 20-23   LBA OF START OF DATA BLOCKS     = 00 00 01 00
; 510-511 BB66 - SFS SIGNATURE
;------------------------------------------------------------------------
sfs_format:
        ; set up data_start to first data block 00000100
        stz data_start + 0
        lda #$01
        sta data_start + 1
        stz data_start + 2
        stz data_start + 3

        ; step 1: zero out the buffer
        ldx #0
@1:
        stz sector_buffer,x
        stz sector_buffer + 256, x
        inx
        bne @1

        ; step 2: add the volume ID
        ldx #0
@2:
        lda VolumeID,x
        sta sector_buffer,x
        inx
        cpx #(VolumeID_end-VolumeID)
        bne @2

        lda VolumeIDSig
        sta sector_buffer + 510
        lda VolumeIDSig + 1
        sta sector_buffer + 511

        stz sector_lba + 0
        stz sector_lba + 1
        stz sector_lba + 2
        stz sector_lba + 3

        jsr sdcard_write_sector

        lda #<strVolumeID
        ldx #>strVolumeID
        jsr acia_puts

        lda #$80
        sta sector_lba + 0      ; start at 0x80
        stz sector_lba + 1
        stz sector_lba + 2
        stz sector_lba + 3

@4:
        jsr populate_sector_buffer
        jsr sdcard_write_sector
        lda #'.'
        jsr acia_putc
        lda sector_lba + 0
        and #$0F                ; print 16 '.' per line
        bne @5
        jsr primm
        .byte 10,13,0
@5:
        inc sector_lba + 0
        beq @done
        bne @4
@done:
        jsr primm
        .byte 10,13,"Format complete!",0
        rts

populate_sector_buffer:
        ; zero out index (first empty buffer then write it 0x80 times to the card.)
        ldx #0
@1:
        stz sector_buffer,x
        stz sector_buffer + 256, x
        inx
        bne @1

        ; now write the lba into index_lba for each index.
        lda #<sector_buffer
        sta sfs_ptr
        lda #>sector_buffer
        sta sfs_ptr + 1
@2:
        ldy #26                 ; offset for index_lba
        lda sector_lba + 0
        sta (sfs_ptr), y
        iny
        lda sector_lba + 1
        sta (sfs_ptr), y
        iny
        lda sector_lba + 2
        sta (sfs_ptr), y
        iny
        lda sector_lba + 3
        sta (sfs_ptr), y

        ; data start.
        ldy #22
        lda data_start + 0
        sta (sfs_ptr), y
        iny
        lda data_start + 1
        sta (sfs_ptr), y
        iny
        lda data_start + 2
        sta (sfs_ptr), y
        iny
        lda data_start + 3
        sta (sfs_ptr), y
        
        clc
        lda data_start + 0
        adc #$80
        sta data_start + 0
        lda data_start + 1
        adc #0
        sta data_start + 1
        lda data_start + 2
        adc #0
        sta data_start + 2
        lda data_start + 3
        adc #0
        sta data_start + 3
        
        clc
        lda sfs_ptr
        adc #32
        sta sfs_ptr
        lda sfs_ptr + 1
        adc #0
        sta sfs_ptr + 1
        cmp #>sector_buffer_end
        bne @2
        sec
        rts

.rodata
VolumeID:       .byte "SFS.DISK"         ; 8 bytes volume ID
                .byte "0001"             ; 4 bytes VERSION
                .byte $80, $00, $00, $00 ; 4 bytes INDEX LBA
                .byte $80, $00, $00, $00 ; 4 bytes LAST INDEX LBA
                .byte $00, $01, $00, $00 ; 4 BYTES DATA START LBA
VolumeID_end:

VolumeIDSig:    .byte $BB, $66

strVolumeID:    .byte 10, 13, "Volume ID DONE"
                .byte 10, 13, "Clearing Indexes", 0
