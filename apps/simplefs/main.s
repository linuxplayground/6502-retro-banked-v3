.include "kern.inc"
.include "sdcard.inc"
.include "sfs.inc"
.include "structs.inc"
.import sector_lba, sector_buffer, sector_buffer_end, index

.import primm

.bss
cmdaddr: .dword 0; 4
tmp1:   .byte 0
cmdbuf: .res $100-5

.code
        nop
        nop
        nop
        jsr primm
        .byte 10, 13, "SIMPLE FILE SYSTEM (SFS)", 0

        jsr sdcard_init
        jsr sfs_mount

        ; read user input
prompt:
        jsr primm
        .byte 10, 13, "] ", 0
        ldx #0
@1:
        jsr acia_getc
        cmp #$0a
        beq cmd_process
        cmp #$0d
        beq cmd_process
        jsr acia_putc
        cmp #$08
        bne @2
        lda #$20
        jsr acia_putc
        lda #$08
        jsr acia_putc
        bra @1
@2:
        sta cmdbuf,x
        inx
        cpx #$80
        beq prompt
        bra @1
        rts

cmd_process:
        ldx #0
@parse:
        lda cmdbuf,x
        inx
        cmp #'f'
        beq @cmd_format
        cmp #'c'
        beq @cmd_create
        cmp #'d'
        beq @cmd_dump_sector
        cmp #'e'
        beq @cmd_erase
        cmp #'i'
        beq @cmd_dump_index
        cmp #'l'
        beq @cmd_load
        cmp #'m'
        beq @cmd_mount
        cmp #'w'
        beq @cmd_write
        cmp #'r'
        beq @cmd_read
        cmp #'t'
        beq @cmd_test
        cmp #'q'
        beq @cmd_quit
        cmp #'v'
        beq @cmd_volid
        jmp prompt
@cmd_format:
        jmp cmd_format
@cmd_create:
        jmp cmd_create
@cmd_dump_index:
        jmp cmd_dump_index
@cmd_erase:
        jmp cmd_erase
@cmd_dump_sector:
        jmp cmd_dump_sector
@cmd_mount:
        jmp cmd_mount
@cmd_load:
        jmp cmd_load
@cmd_write:
        jmp cmd_write
@cmd_read:
        jmp cmd_read
@cmd_test:
        jmp cmd_test
@cmd_volid:
        jmp cmd_dump_volid
@cmd_quit:
        rts

cmd_mount:
        jsr sfs_mount
        jsr cmd_dump_volid
        jsr primm
        .byte 10,13,"DIRECTORY SIZE ATR  NAME",10,13,0
        jsr sfs_open_first_index_block
@loop:
        jsr sfs_read_next_index
        bcc @done
        lda index + sIndex::attrib
        cmp #$FF
        beq @loop
        lda index + sIndex::filename + 0
        beq @done
        jsr @printline
        bra @loop  
@done:
        jmp prompt
@printline:
        lda index + sIndex::start + 3
        jsr prbyte
        lda index + sIndex::start + 2
        jsr prbyte
        lda index + sIndex::start + 1
        jsr prbyte
        lda index + sIndex::start + 0
        jsr prbyte
        jsr primm
        .byte "  ",0
        lda index + sIndex::size + 1
        jsr prbyte
        lda index + sIndex::size + 0
        jsr prbyte
        jsr primm
        .byte "  ",0
        lda index + sIndex::attrib
        jsr prbyte
        jsr primm
        .byte "  ",0
        ldx #0
:       lda index + sIndex::filename,x
        jsr acia_putc
        inx
        cpx #21
        bne :-
        jsr primm
        .byte 10,13,0
        rts


cmd_format:
        jsr primm
        .byte 10, 13, "FORMAT:", 0
        jsr sfs_format
        jsr sdcard_init
        jsr sfs_mount
        bcs @1
        jmp convert_error
@1:

cmd_dump_volid:
        jsr sfs_dump_volid
        rts

cmd_create:
;=========== DEBUG RETURN -----------
        jsr primm
        .byte 10, 13, "CREATE", 0

        lda #<strTestFile
        sta sfs_fn_ptr
        lda #>strTestFile
        sta sfs_fn_ptr + 1

        jsr sfs_create
        bcs @2
        jmp convert_error
@2:
        jmp prompt

cmd_write:
        jsr primm
        .byte 10, 13, "WRITE DATA", 0

        lda #$80
        sta sfs_bytes_rem
        lda #$00
        sta sfs_bytes_rem + 1

        lda #$00
        sta sfs_data_ptr
        lda #$b0
        sta sfs_data_ptr + 1

        jsr sfs_write
        jmp prompt

cmd_read:
        jsr primm
        .byte 10, 13, "READ BLOCK", 0
@1:
        lda cmdbuf,x
        cmp #$20
        bne @2
        inx
        bra @1
@2:
        pha                     ; save high nibble
        txa
        tay                     ; use y from now on.

        iny
        lda cmdbuf,y
        tax
        pla
        jsr hex_str_to_byte
        sta sector_lba + 3

        iny
        lda cmdbuf,y
        pha
        iny
        lda cmdbuf,y
        tax
        pla
        jsr hex_str_to_byte
        sta sector_lba + 2

        iny
        lda cmdbuf,y
        pha
        iny
        lda cmdbuf,y
        tax
        pla
        jsr hex_str_to_byte
        sta sector_lba + 1

        iny
        lda cmdbuf,y
        pha
        iny
        lda cmdbuf,y
        tax
        pla
        jsr hex_str_to_byte
        sta sector_lba + 0

        jsr sdcard_read_sector
        jsr primm
        .byte 10, 13, "READ ONE SECTOR: ",0
        lda sector_lba + 3
        jsr prbyte
        lda sector_lba + 2
        jsr prbyte
        lda sector_lba + 1
        jsr prbyte
        lda sector_lba + 0
        jsr prbyte
        
        jmp prompt

cmd_load:
        lda #<strTestFile
        sta sfs_fn_ptr
        lda #>strTestFile
        sta sfs_fn_ptr + 1

        jsr sfs_find
        bcc @error

        lda #$00
        sta sfs_data_ptr
        lda #$80
        sta sfs_data_ptr + 1

        jsr sfs_read
        bcc @error
        jmp prompt
@error:
        jmp convert_error

cmd_dump_sector:
        jsr primm
        .byte 10, 13, 0

        lda #<sector_buffer
        sta sfs_ptr
        lda #>sector_buffer
        sta sfs_ptr + 1
@1:
        lda sfs_ptr + 1
        jsr prbyte
        lda sfs_ptr
        jsr prbyte
        jsr primm
        .byte ": ",0
@2:
        lda (sfs_ptr)
        jsr prbyte
        lda #' '
        jsr acia_putc
        
        inc sfs_ptr
        bne :+
        inc sfs_ptr + 1
        lda sfs_ptr + 1
        cmp #>sector_buffer_end
        beq @3
:
        lda sfs_ptr
        and #$0F
        bne @2
        jsr primm
        .byte 10, 13, 0

        bra @1
@3:
        jmp prompt

cmd_dump_index:
        jsr primm
        .byte 10, 13, "INDEX DATA:",0
        ldx #0
@1:
        lda index + sIndex::filename,x
        cmp #$20
        bne :+
        lda #'.'
:
        jsr acia_putc
        inx
        cpx #21
        bne @1
        jsr primm
        .byte 10, 13, "ATTRIBUTE: ",0
        lda index + sIndex::attrib
        jsr prbyte

        jsr primm
        .byte 10, 13, "START: ",0

        ldx #3
@2:
        lda index + sIndex::start,x
        jsr prbyte
        dex
        bpl @2

@3:
        jsr primm
        .byte 10, 13, "SIZE: ",0
        ldx #1
@3a:
        lda index + sIndex::size,x
        jsr prbyte
        dex
        bpl @3a
@4:
        jsr primm
        .byte 10, 13, "INDEX LBA: ",0
        ldx #3
@4a:
        lda index + sIndex::index_lba,x
        jsr prbyte
        dex
        bpl @4a
@5:
        jmp prompt

cmd_test:
        ldx #16

@1:
        phx
        jsr primm
        .byte 10, 13, "CREATE", 0

        lda #<strTestFile
        sta sfs_fn_ptr
        lda #>strTestFile
        sta sfs_fn_ptr + 1

        jsr sfs_create
        bcs @2
        jmp convert_error
@2:
        jsr primm
        .byte 10, 13, "WRITE DATA", 0

        lda #$80
        sta sfs_bytes_rem
        lda #$04
        sta sfs_bytes_rem + 1

        lda #$00
        sta sfs_data_ptr
        lda #$08
        sta sfs_data_ptr + 1

        jsr sfs_write
        plx
        dex
        bne @1
        jmp prompt        

cmd_erase:
        lda #<strTestFile
        sta sfs_fn_ptr
        lda #>strTestFile
        sta sfs_fn_ptr + 1
        jsr sfs_find
        bcc convert_error
        jsr sfs_delete
        bcc convert_error
        jmp prompt

convert_error:

        jsr primm
        .byte 10, 13, "ERROR: ", 0

        lda #<strTable
        sta sfs_ptr
        lda #>strTable
        sta sfs_ptr + 1

        lda sfs_errno
        asl
        ldy #1
        lda (sfs_ptr),y
        tax
        dey
        lda (sfs_ptr),y
        jsr acia_puts
        jmp prompt


; A = high nibble, X = low nibble
; result in A
hex_str_to_byte:
        jsr     @asc_hex_to_bin          ; convert to number - result is in A
        asl                            ; shift to high nibble
        asl
        asl
        asl
        sta     tmp1                    ; and store
        txa                             ; get the low nibble character
        jsr     @asc_hex_to_bin          ; convert to number - result is in A
        ora     tmp1                    ; OR with previous result
        rts

@asc_hex_to_bin:                        ; assumes ASCII char val is in A
        sec
        sbc     #$30                    ; subtract $30 - this is good for 0-9
        cmp     #10                     ; is value more than 10?
        bcc     @asc_hex_to_bin_end      ; if not, we're okay
        sbc     #$07                    ; otherwise subtract another $07 for A-F
@asc_hex_to_bin_end:
        rts        

.segment "RODATA"

strTable:
        .addr strERRNO_OK
        .addr strERRNO_DISK_ERROR
        .addr strERRNO_SECTOR_READ_FAILED
        .addr strERRNO_SECTOR_WRITE_FAILED
        .addr strERRNO_END_OF_INDEX_ERROR
        .addr strERRNO_FILE_NOT_FOUND_ERROR

strERRNO_OK:                    .asciiz "OK"
strERRNO_DISK_ERROR:            .asciiz "Bad DISK error"
strERRNO_SECTOR_READ_FAILED:    .asciiz "Sector read failed"
strERRNO_SECTOR_WRITE_FAILED:   .asciiz "Sector write failed"
strERRNO_END_OF_INDEX_ERROR:    .asciiz "End of index sectors"
strERRNO_FILE_NOT_FOUND_ERROR:  .asciiz "File not found"

strTestFile:    .asciiz "TESTFILE.TXT"