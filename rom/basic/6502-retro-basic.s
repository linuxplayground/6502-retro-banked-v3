; contains additional commands for EH Basic
; 
; BYE - Quits EHBASIC
; CLS - CLEAR Screen by issuing Ansi escape sequence "ESC [J2"

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
        
        lda     #MONITOR_BANK
        jmp     rstfar

load:
save:
        rts
        
strAnsiCLSHome: .byte $0D,$0A, $1b, "[2J", $1b, "[H", $0
strByeMessage:  .byte $0D,$0A,"Exiting ehBasic now...", $0
