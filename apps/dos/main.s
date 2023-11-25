.include "../../rom/fat32/regs.inc"
.include "../../rom/inc/kern.inc"
.include "../../rom/inc/banks.inc"
.include "../../rom/inc/fat32.inc"

.import ram_bank, rom_bank, fat32_dirent

.importzp fat32_ptr, fat32_ptr2, fat32_bufptr, fat32_lfn_bufptr

.macro fat32_call addr
        jsr jsrfar
        .word addr
        .byte FAT32_BANK
.endmacro

.macro kern_call addr
        jsr jsrfar
        .word addr
        .byte MONITOR_BANK
.endmacro

ptr1 = $f0
.code

main:
        lda #1
        sta rambankreg

        lda #<strWelcome
        ldx #>strWelcome
        kern_call acia_puts

        fat32_call sdcard_init
        bcc exit      

        fat32_call fat32_init
        bcc exit

        lda #0
        fat32_call fat32_alloc_context

        lda #<strRoot
        sta fat32_ptr
        lda #>strRoot
        sta fat32_ptr + 1
        fat32_call fat32_open_dir
        bcc exit
        fat32_call fat32_read_dirent
        bcc exit
        jmp print_dir
exit:
        rts

print_dir:
        lda fat32_dirent + dirent::attributes
        cmp #$20
        bne print_dir_next

        lda #<strEndl
        ldx #>strEndl
        kern_call acia_puts


        ldy #0
:       lda fat32_dirent + dirent::name, y
        beq :+
        kern_call acia_putc
        iny
        beq :+
        jmp :-
:
        lda #':'
        kern_call acia_putc
        lda fat32_dirent + dirent::attributes
        kern_call prbyte

print_dir_next:
        fat32_call fat32_read_dirent
        bcs print_dir

        rts


jsrfar:
        .include "../../rom/inc/jsrfar.inc"

.rodata

strWelcome: .byte $0a,$0d, "WELCOME TO DOS",$0
strEnd:     .byte $0a,$0d, "QUITTING ...",$0
strRoot:    .byte "/",$0
strEndl:    .byte $0a,$0d,$0