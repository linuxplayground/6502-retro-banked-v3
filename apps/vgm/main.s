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

prbyte    = $D13E
sn_silence = $D3C0
sn_start  = $D39F
sn_send   = $D427
sn_stop   = $D3BC
primm     = $D447
acia_putc = $D63D

.code
    jsr sn_start
    jsr sn_silence
    jsr vgm_setup
    ldy #$80
    jsr vgm_play
    jsr sn_stop
    rts

; sets up the VGM data stream
vgm_setup:
    lda #1
    sta ram_bank
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
    iny
    bne :+
    jsr incvgmptrh
:   jmp vgm_play

incvgmptrh:
    lda #'.'
    jsr acia_putc

    inc vgmptr + 1
    lda vgmptr + 1
    cmp #$C0
    bne :+

    inc ram_bank
    lda ram_bank
    sta rambankreg
    nop
    nop

    lda ram_bank
    jsr prbyte

    lda #$A0
    sta vgmptr + 1
    ldy #0
:   rts

command:
    iny
    bne :+
    jsr incvgmptrh
:   lda (vgmptr),y
    jsr sn_send
    jmp vgm_next

wait:
    iny
    bne :+
    jsr incvgmptrh
:   lda (vgmptr),y
    sta vgmwaitl
    iny
    bne :+
    jsr incvgmptrh
:   lda (vgmptr),y
    sta vgmwaith
    jsr vgmwait
    jmp vgm_next

n1:
    lda (vgmptr),y
    cmp #$70
    beq :+
    and #$0f
    sta vgmwaitl
    stz vgmwaith
    jsr vgmwait
:
    jmp vgm_next

end:
    stz ram_bank
    stz rambankreg
    jmp sn_silence

sixtieth:
    lda #$df
    sta vgmwaitl
    lda #$02
    sta vgmwaith
    jsr vgmwait
    jmp vgm_next

; at 4mhz we want 91 clocks for a single sample.
; this works out to 90 clock cycles. which is ~22uS
vgmwait:                    ; (6) Cycles to prep the and execute the jsr
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

vgm_start:  .dword 0

