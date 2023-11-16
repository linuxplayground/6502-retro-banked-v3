; contains additional commands for EH Basic
; 
; BYE - Quits EHBASIC
; CLS - CLEAR Screen by issuing Ansi escape sequence "ESC [J2"
.import rstfar

.code
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
        lda     #$00                    ; switch to bank 0 and reset.
        jmp     rstfar

load:
save:
        rts
        
strAnsiCLSHome: .byte $0D,$0A, $1b, "[2J", $1b, "[H", $0
strByeMessage:  .byte $0D,$0A,"Exiting ehBasic now...", $0
.segment "SYSCALLS"
.byte $0