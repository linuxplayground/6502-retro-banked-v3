.include "kern.inc"
.include "sdcard.inc"
.include "sfs.inc"
.include "structs.inc"
.import sector_lba, sector_buffer, sector_buffer_end, index
.import debug_sector_lba

dos_ptr = $C8

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
        jsr sfs_init
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
        cmp #'q'
        bne :+
        rts
:
        cmp #'d'
        beq @jmp_cmd_dump_sector
        cmp #'o'
        beq @jmp_open
        cmp #'r'
        beq @jmp_read_byte
        cmp #'c'
        beq @jmp_close
        cmp #'p'
        beq @jmp_read_page
        cmp #'w'
        beq @jmp_write_page

        jmp prompt
@jmp_open:
        jmp cmd_open
@jmp_read_byte:
        jmp cmd_read_byte
@jmp_close:
        jmp cmd_close
@jmp_read_page:
        jmp cmd_read_page
@jmp_cmd_dump_sector:
        jmp cmd_dump_sector
@jmp_write_page:
        jmp cmd_write_page

cmd_open:
        lda #<strTestFile
        sta sfs_fn_ptr
        lda #>strTestFile
        sta sfs_fn_ptr + 1

        jsr sfs_create
        bcc @error
        lda #2
        jsr sfs_open
        bcc @error
        jsr debug_sector_lba
        jmp prompt
@error:
        jmp convert_error

cmd_read_byte:
        jsr sfs_read_byte
        bcc @error
        sta (dos_ptr)
        inc dos_ptr
        bne :+
        inc dos_ptr + 1
:
        jsr acia_putc
        jsr primm
        .byte 10, 13, 0
        lda sfs_ptr + 1
        jsr prbyte
        lda sfs_ptr + 0
        jsr prbyte

        jmp prompt
@error:
        jmp convert_error

cmd_read_page:
        jsr primm
        .byte 10, 13, 0

        ldx #0
@1:
        jsr sfs_read_byte
        bcc @close
        jsr acia_putc
        cmp #$0a
        bne :+
        lda #$0d
        jsr acia_putc
:       inx
        bne @1
        ldx #0
@2:
        jsr sfs_read_byte

        bcc @close
        jsr acia_putc
        cmp #$0a
        bne :+
        lda #$0d
        jsr acia_putc
:       inx
        bne @2
@end:
        jsr primm
        .byte 10, 13, "BYTES REM: ",0
        lda sfs_bytes_rem + 1
        jsr prbyte
        lda sfs_bytes_rem + 0
        jsr prbyte
        jmp prompt
@close:
        lda sfs_errno
        cmp #ERRNO_OK
        beq @done
        jmp cmd_close
@done:
        jsr primm
        .byte 10, 13, "END OF FILE",0
        ; fall through
cmd_close:
        jsr sfs_close
        jmp convert_error


; writes 0 - 255  so that we fill half a sector.
cmd_write_page:
        lda #$20
@loop:
        jsr sfs_write_byte
        bcc @error
        inc
        cmp #127
        bne @loop
        jmp prompt
@error:
        jmp convert_error


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

.segment "RODATA"

strTable:
        .addr strERRNO_OK
        .addr strERRNO_DISK_ERROR
        .addr strERRNO_SECTOR_READ_FAILED
        .addr strERRNO_SECTOR_WRITE_FAILED
        .addr strERRNO_END_OF_INDEX_ERROR
        .addr strERRNO_FILE_NOT_FOUND_ERROR
        .addr strERRNO_INVALID_MODE_ERROR

strERRNO_OK:                    .asciiz "OK"
strERRNO_DISK_ERROR:            .asciiz "Bad DISK error"
strERRNO_SECTOR_READ_FAILED:    .asciiz "Sector read failed"
strERRNO_SECTOR_WRITE_FAILED:   .asciiz "Sector write failed"
strERRNO_END_OF_INDEX_ERROR:    .asciiz "End of index sectors"
strERRNO_FILE_NOT_FOUND_ERROR:  .asciiz "File not found"
strERRNO_INVALID_MODE_ERROR:    .asciiz "Invalid file mode"

strTestFile:    .asciiz "TEST4.BAS"