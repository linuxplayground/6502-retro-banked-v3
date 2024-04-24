; vim: ft=asm_ca65
; contains additional commands for EH Basic
; 
; BYE - Quits EHBASIC
; CLS - CLEAR Screen by issuing Ansi escape sequence "ESC [J2"
; LOAD "FILENAME.BAS" - Loads a FILENAME
; SAVE "FILENAME.BAS" - Saves current program into FILENAME.

.macro doscall func
        jsr jsrfar
        .word func
        .byte DOS_BANK
.endmacro

jsrfar:
.include "jsrfar.inc"

retro_cls:
        PHA
        PHY
        lda     #<strAnsiCLSHome
        ldy     #>strAnsiCLSHome
        jsr     LAB_18C3                ; print null terminated string
        PLY
        PLA
        rts

retro_bye:
        lda     #<strByeMessage
        ldy     #>strByeMessage
        jsr     LAB_18C3                ; print null terminated string
        
        lda     #DOS_BANK
        jmp     rstfar

retro_beep:
        doscall sn_beep 
       rts

load:
        lda #1                          ; open in read mode
        jsr open_file
        bcs :+
        rts
:
        ; save stack as NEW destroys it
        tsx
        inx
        lda $100,x
        sta ptr1
        inx
        lda $100,x
        sta ptr1 + 1

        jsr LAB_1463                    ; NEW

        ; restore stack
        lda ptr1 + 1
        pha
        lda ptr1
        pha

        ; redirect input
        lda #<fread
        sta VEC_IN + 0
        lda #>fread
        sta VEC_IN + 1

        ; redirect output to null
        lda #<nullout
        sta VEC_OUT + 0
        lda #>nullout
        sta VEC_OUT + 1

        jsr LAB_1319
        rts

save:
        lda #2
        jsr open_file
        bcs :+
        rts
:
        lda #<fwrite                    ; redirect output to file
        sta VEC_OUT + 0
        lda #>fwrite
        sta VEC_OUT + 1

        jsr LAB_14BD                    ; do LIST

        lda #<ACIAout                   ; restore output to serial.
        sta VEC_OUT + 0
        lda #>ACIAout
        sta VEC_OUT + 1

        doscall sfs_close
        bcs :+
        ldx #$28
        jmp LAB_XERR
:
        clc
        rts

; Call with openmode (1 or 2) in A
open_file:
        sta tmp1                ; save the mode for later
        ; init the sdcard and sfs
        doscall sfs_init
        doscall sfs_mount
        bcs :+
        ldx #$24
        jmp LAB_XERR
:
        ; fetch filename from command
        jsr LAB_EVEX
        lda Dtypef
        bne :+
        ldx #$02
        jmp LAB_XERR            ; syntax error
:
        jsr LAB_22B6
        ; filename is pointed to by X/Y
        stx sfs_fn_ptr + 0
        sty sfs_fn_ptr + 1
        tay                     ; length in A
        lda #0
        sta (sfs_fn_ptr),Y
        
        lda tmp1
        cmp #2
        bne @find               ; if we are writing - always call create.
        doscall sfs_create      ; always overwrites.
        bcs :+                  ; create ok - branch to open
        ldx #$26                ; File open error
        jmp LAB_XERR
:
        bra @open
@find:                          ; otherwise find the file to open
        doscall sfs_find        ; for read access
        bcs @open
        ldx #$26
        jmp LAB_XERR
@open:
        lda tmp1
        doscall sfs_open
        bcs :+
        ldx #$26
        jmp LAB_XERR            ; failed to open file.
:
        rts

fwrite:
        phx
        phy
        doscall sfs_write_byte
        ply
        plx
        rts

fread:
        phx
        phy
        doscall sfs_read_byte
        ply
        plx
        bcc fread_error
        cmp #$0a
        bne nullout
        lda #$0d
nullout:
        sec
        rts
fread_error:
        lda sfs_errno
        beq close_file
        ldx #$2A
        jmp LAB_XERR

close_file:
        doscall sfs_close
        bcs :+
        ldx #$28
        jmp LAB_XERR
:
        lda #<ACIAout
        sta VEC_OUT + 0
        lda #>ACIAout
        sta VEC_OUT + 1

        lda #<ACIAin
        sta VEC_IN + 0
        lda #>ACIAin
        sta VEC_IN + 1
        
        lda #<strReady
        ldy #>strReady
        jsr LAB_18C3

        jsr LAB_1477
        jmp LAB_1319

retro_dir:
        doscall sfs_init
        doscall sfs_mount
        doscall dos_bdir
        rts

strAnsiCLSHome: .byte $0D,$0A, $1b, "[2J", $1b, "[H", $0
strByeMessage:  .byte $0D,$0A,"Exiting ehBasic now...", $0
strReady:       .byte $0D,$0A,"Ready",$0A,$0D,$0
