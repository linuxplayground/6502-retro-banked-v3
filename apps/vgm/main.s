; vim: ft=asm_ca65 ts=4 sw=4 expandtab ai
.include "io.inc"

SD_SCK  = %00000001
SD_CS   = %00000010
SN_WE   = %00000100
SN_READY= %00001000
SD_MOSI = %10000000

ram_bank  = $13

vgmptr    = $F0
vgmptrh   = $F1
vgmwaitl  = $F2
vgmwaith  = $F3

acia_putc = $FF09
prbyte    = $FF0F
primm     = $FF15
sn_start  = $FF6C
sn_stop   = $FF6F
sn_silence= $FF72
sn_send   = $FF84

.code
    jsr sn_start
    jsr sn_silence
    jsr vgm_setup
    ldy #$80        ; all samples I have seen begin at 0x80 in the file.
    jsr vgm_play
    jsr sn_stop
    rts

; sets up the VGM data stream
vgm_setup:
    lda #1          ; this player expects the song file to have been loaded
    sta ram_bank    ; into extended memory starting in BANK 1 at 0xA000
    sta rambankreg
    ; assign pointers
    stz vgmptr
    lda #$A0
    sta vgmptr + 1
    rts


vgm_play:
    lda (vgmptr),y
    cmp #$50
    beq @command
    cmp #$66
    beq @end
    cmp #$61
    beq @wait
    cmp #$62
    beq @sixtieth
    and #$F0
    cmp #$70
    beq @n1

    jsr prbyte
    jmp end

@command:
    jmp command
@wait:
    jmp wait
@n1:
    jmp n1
@sixtieth:
    jmp sixtieth
@end:
    jmp end
@cmd_a0:
    iny
    bne :+
    jsr incvgmptrh
    iny
    bne :+
    jsr incvgmptrh
:   rts

vgm_next:
    iny                 ; increment the y index into the data pointed to by
    bne :+              ; vgmptr and ensure that ram bank boundaries are managed
    jsr incvgmptrh
:   jmp vgm_play

incvgmptrh:
    lda #'.'            ; print a '.' every 256 bytes
    jsr acia_putc

    inc vgmptr + 1
    lda vgmptr + 1
    cmp #$C0            ; have we crossed into ROM?
    bne :+              ; no - return

    inc ram_bank        ; move to next ram bank.
    lda ram_bank
    sta rambankreg
    nop                 ; the 74LS273 registers I am using appear to
    nop                 ; need these extra cycles.

    lda ram_bank        ; show the new rambank to the user.
    jsr prbyte

    lda #$A0            ; reset the vgmptr to the start of the ram
    sta vgmptr + 1      ; bank
    ldy #0              ; reset y to 0.
:   rts

command:
    iny
    bne :+
    jsr incvgmptrh
:   lda (vgmptr),y
    jsr sn_send
    jmp vgm_next

wait:                   ; get the next two bytes taking care to account
    iny                 ; for crossing to the next ram bank.  These form
    bne :+              ; the 16 bit wide number of samples to wait for.
    jsr incvgmptrh
:   lda (vgmptr),y
    sta vgmwaitl
    iny
    bne :+
    jsr incvgmptrh
:   lda (vgmptr),y
    sta vgmwaith        ; once the vgmwait word has the number of samples
    jsr vgmwait         ; to wait for, go ahead and perform the wait.
    jmp vgm_next

n1:                     ; this special case, meand wait for up to 15 sample
    lda (vgmptr),y      ; periods
    cmp #$70
    beq :+
    and #$0f
    sta vgmwaitl
    stz vgmwaith
    jsr vgmwait
:
    jmp vgm_next

end:                    ; reset the rambank and silence the PSG
    stz ram_bank
    stz rambankreg
    jmp sn_silence

sixtieth:               ; as given by the datasheet wait for exactly 1/60
    lda #$df            ; of a second.
    sta vgmwaitl
    lda #$02
    sta vgmwaith
    jsr vgmwait
    jmp vgm_next

; this routine waste a fairly large number of bytes.  As this is the ONLY program
; being executed from Low memory when it's running, there is plenty of space for
; inefficient yet fast code.  A bunch-o-nops is a perfectly reasonable way to kill
; precises amounts of time in 6502 Assembly if you have the room.  Certainly it can
; be done with VIA timers or clever loops, but with the ram available this seems to
; work just fine.
;
; at 4mhz we want 91 clocks for a single sample.
; this works out to 90 clock cycles. which is ~22uS
vgmwait:                    ; (6) Cycles to prep and execute the jsr
    lda vgmwaitl            ; (3)
    bne @wait_samples_1     ; (2)   (could be 3 if branching across page)
    lda vgmwaith            ; (3)
    beq @return             ; (2)   (could be 3 if branching across page)
    dec vgmwaith            ; (5) zeropage decrement
@wait_samples_1:
    dec vgmwaitl            ; (5) zeropage decrement
    ; kill some cycles between loops.  Adjust as required.
    .repeat 30
        nop                 ; (2 * 30 = 60)
    .endrepeat
    jmp vgmwait             ; (3)   loop = 29 cycles
@return:
    rts                     ; (6)   6 cycles to return

