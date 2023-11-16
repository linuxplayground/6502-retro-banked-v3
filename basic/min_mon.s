; minimal monitor for EhBASIC and 6502 simulator V1.05
; tabs converted to space, tabwidth=6

; To run EhBASIC on the simulator load and assemble [F7] this file, start the simulator
; running [F6] then start the code with the RESET [CTRL][SHIFT]R. Just selecting RUN
; will do nothing, you'll still have to do a reset to run the code.
      .include "basic.s"
      .include "6502-retro-basic.s"
      ; .include "acia.inc"

      .import jsfar
; put the IRQ and MNI code in RAM so that it can be changed

IRQ_vec     = VEC_SV+2        ; IRQ code vector
NMI_vec     = IRQ_vec+$0A     ; NMI code vector

; now the code. all this does is set up the vectors and interrupt code
; and wait for the user to select [C]old or [W]arm start. nothing else
; fits in less than 128 bytes

      .code
; reset vector points here

RES_vec
      CLD                     ; clear decimal mode
      LDX   #$FF              ; empty stack
      TXS                     ; set the stack
      JSR ACIAsetup           ; disabled ACIA interrutps.

; set up vectors and interrupt code, copy them to page 2

      LDY   #END_CODE-LAB_vec ; set index/count
LAB_stlp
      LDA   LAB_vec-1,Y       ; get byte from interrupt code
      STA   VEC_IN-1,Y        ; save to RAM
      DEY                     ; decrement index/count
      BNE   LAB_stlp          ; loop if more to do

; now do the signon message, Y = $00 here

LAB_signon
      LDA   LAB_mess,Y        ; get byte from sign on message
      BEQ   LAB_nokey         ; exit loop if done

      JSR   V_OUTP            ; output character
      INY                     ; increment index
      BNE   LAB_signon        ; loop, branch always

LAB_nokey
      JSR   V_INPT            ; call scan input device
      BCC   LAB_nokey         ; loop if no key

      AND   #$DF              ; mask xx0x xxxx, ensure upper case
      CMP   #'W'              ; compare with [W]arm start
      BEQ   LAB_dowarm        ; branch if [W]arm start

      CMP   #'C'              ; compare with [C]old start
      BNE   RES_vec           ; loop if not [C]old start

      JMP   LAB_COLD          ; do EhBASIC cold start

LAB_dowarm
      JMP   LAB_WARM          ; do EhBASIC warm start

; Polled 65c51 I/O routines adapted to EhBASIC. Delay routine from
; http://forum.6502.org/viewtopic.php?f=4&t=2543&start=30#p29795
; ACIA_DATA    = $9F10
; ACIA_STATUS  = $9F11
ACIA_COMMAND =   $9F12
; ACIA_CONTROL = $9F13

ACIA_PARITY_DISABLE          = %00000000
ACIA_ECHO_DISABLE            = %00000000
ACIA_TX_INT_DISABLE_RTS_LOW  = %00001000
ACIA_RX_INT_ENABLE           = %00000000
ACIA_RX_INT_DISABLE          = %00000010
ACIA_DTR_LOW                 = %00000001

ACIAsetup:
;         lda #$00
;         sta ACIA_STATUS
        lda #(ACIA_PARITY_DISABLE | ACIA_ECHO_DISABLE | ACIA_TX_INT_DISABLE_RTS_LOW | ACIA_RX_INT_DISABLE | ACIA_DTR_LOW)
        sta ACIA_COMMAND
;         lda #$10
;         sta ACIA_CONTROL
        rts

ACIAout
      ; jmp _acia_putc
      jsr   jsfar
      .word $FF04
      .byte $00
      rts

ACIAin
      ; jmp _acia_getc_nw
      jsr   jsfar
      .word $FF06
      .byte $00
      rts

; vector tables

LAB_vec
      .word ACIAin            ; byte in from simulated ACIA
      .word ACIAout           ; byte out to simulated ACIA
      .word load              ; null load vector for EhBASIC
      .word save              ; null save vector for EhBASIC
      .word RES_vec

; EhBASIC IRQ support

IRQ_CODE
      PHA                     ; save A
      LDA   IrqBase           ; get the IRQ flag byte
      LSR                     ; shift the set b7 to b6, and on down ...
      ORA   IrqBase           ; OR the original back in
      STA   IrqBase           ; save the new IRQ flag byte
      PLA                     ; restore A
      RTI

; EhBASIC NMI support

NMI_CODE
      PHA                     ; save A
      LDA   NmiBase           ; get the NMI flag byte
      LSR                     ; shift the set b7 to b6, and on down ...
      ORA   NmiBase           ; OR the original back in
      STA   NmiBase           ; save the new NMI flag byte
      PLA                     ; restore A
      RTI

END_CODE

LAB_mess
      .byte $0D,$0A,"6502 EhBASIC [C]old/[W]arm ?",$00
                              ; sign on string

.segment "VECTORS"
      .word $0000
      .word RES_vec
      .word $0000