; vim: ft=asm_ca65
.include "vdp.inc"
.include "kern.inc"

.export _vdp_80_col, _vdp_unlock, _vdp_lock, _vdp_print, _vdp_clear_screen
.export _vdp_init_textmode, _vdp_write_reg, _vdp_write_address, _vdp_load_font
.export _vdp_newline, _vdp_write_char, _vdp_console_out

.global vdp
.globalzp vdpptr1,vdpptr2,vdpptr3

.segment "VDPZP" : zeropage

vdpptr1:    .res 2
vdpptr2:    .res 2
vdpptr3:    .res 2

.segment "VDPRAM"
vdp:        .tag sVdp

.code
; a utility function to print out a 16bit value in hex.
_debug16:
    pha
    txa
    jsr prbyte
    pla
    jsr prbyte
    rts

;==============================================
; sets up 80 column text mode
;==============================================
_vdp_80_col:
    lda #$04
    ldx #$00
    jsr _vdp_write_reg
    lda #80
    sta vdp + sVdp::cols
    rts

;==============================================
; unlocks the F18A
;==============================================
_vdp_unlock:
    lda #$1c
    ldx #57
    jsr _vdp_write_reg
    lda #$1c
    ldx #57
    jsr _vdp_write_reg
    rts

;==============================================
; locks the F18A if already unlocked.
;==============================================
_vdp_lock:
    lda #$00
    ldx #57
    jsr _vdp_write_reg
    rts

;==============================================
; inerprets input keys and acts accordingly
; A contains char from terminal
;==============================================
_vdp_console_out:
    cmp #$0a
    beq @newline
    cmp #$0d
    beq @newline
    cmp #$08
    beq @backspace
    cmp #$09
    beq @tab
    jsr _vdp_write_char
    rts
@newline:
    jmp _vdp_newline
@backspace:
    jmp _vdp_backspace
@tab:
    lda vdp + sVdp::vx
    and #%11111100
    clc
    adc #3
    sta vdp + sVdp::vx
:   jmp _vdp_xy_to_nametable

;==============================================
; Print a string to the screen
; AX points to string
;==============================================
_vdp_print:
    sta vdpptr1
    stx vdpptr1 + 1
    ldy #0
:
    lda (vdpptr1),y
    beq @done
    jsr _vdp_write_char
    iny
    bra :-
@done:
    rts

_vdp_write_char:
    pha
    inc vdp + sVdp::vx
    lda vdp + sVdp::cols
    cmp vdp + sVdp::vx
    bcs :+
    stz vdp + sVdp::vx
    inc vdp + sVdp::vy
    lda vdp + sVdp::rows
    cmp vdp + sVdp::vy
    bcs :+
    jsr _vdp_clear_screen
:   pla
    sta F18A_RAM
    rts

;==============================================
; move back, delete char, move back again.
;==============================================
_vdp_backspace:
    lda vdp + sVdp::vx
    beq @nobackspace
    dec vdp + sVdp::vx
    jsr _vdp_xy_to_nametable
    lda #' '
    jsr _vdp_write_char
    dec vdp + sVdp::vx
    jmp _vdp_xy_to_nametable
@nobackspace:
    rts

;==============================================
; move the current cursor position to the start
; of the next line.
;==============================================
_vdp_newline:
    stz vdp + sVdp::vx
    inc vdp + sVdp::vy
    lda vdp + sVdp::vy
    cmp vdp + sVdp::rows
    bcc _vdp_xy_to_nametable
    jmp _vdp_clear_screen

    ;fall through
_vdp_xy_to_nametable:
    copyptr vdp + sVdp::nametable, vdpptr1
    ;debug16 vdpptr1
    lda vdp + sVdp::vy
    beq @addx
    tay
@loop:
    lda vdp + sVdp::cols
    cmp #80
    bne :+
    add16 vdpptr1,80
    bra @decy
:   cmp #40
    bne :+
    add16 vdpptr1,40
    bra @decy
:   add16 vdpptr1,32
@decy:
    dey
    bne @loop
@addx:
    lda vdp + sVdp::vx
    clc
    adc vdpptr1
    sta vdpptr1
    lda vdpptr1 +1
    adc #0
    sta vdpptr1 + 1
@set_write_address:
    ;debug16 vdpptr1
    lda vdpptr1
    ldx vdpptr1 + 1
    jmp _vdp_write_address

;==============================================
; Write to vdp register
; A = value to write, x = register to write to
;==============================================
_vdp_write_reg:
    sta F18A_REG
    txa
    ora #$80
    sta F18A_REG
    rts

;==============================================
; Set up the vdp for writing at vram address
; A = low byte of vram address, x = high byte
;==============================================
_vdp_write_address:
    sta F18A_REG
    txa
    ora #$40
    sta F18A_REG
    rts

;==============================================
; Fills nametable with spaces
;==============================================
_vdp_clear_screen:
    vdp_set_write_address vdp + sVdp::nametable
    ldy #8
    lda vdp + sVdp::cols
    cmp #80
    beq :+
    ldy #4
:
    lda #' '
:
    ldx #0
:
    sta F18A_RAM
    dex 
    bne :-
    dey 
    bne :--
    stz vdp + sVdp::vx
    stz vdp + sVdp::vy
    vdp_set_write_address vdp + sVdp::nametable
    rts

;==============================================
; Init vdp into standard 40x24 text mode
;==============================================
_vdp_init_textmode:
    set16 vdpptr1, textmode_registers
    jsr vdp_loadregisters
    ; set up vdp struct data
    lda #$00
    sta vdp + sVdp::nametable
    lda #$08
    sta vdp + sVdp::nametable + 1
    stz vdp + sVdp::patterntable
    stz vdp + sVdp::patterntable + 1
    lda #40
    sta vdp + sVdp::cols
    lda #24
    sta vdp + sVdp::rows
    rts

;==============================================
; loads the registers from a 0xff terminated data table pointed to
; by vdpptr1
;==============================================
vdp_loadregisters:
    ldy #0
:   lda (vdpptr1),y
    cmp #$ff
    beq :+
    sta F18A_REG
    iny
    lda (vdpptr1),y
    ora #$80
    sta F18A_REG
    iny
    bra :-
:   rts


;==============================================
; set up font data
; font data is pointed to by vdpptr1
; size of font stored in vdpptr2
;==============================================
_vdp_load_font:
    vdp_set_write_address vdp + sVdp::patterntable
@loop:
    lda (vdpptr1)
    sta F18A_RAM
    ; decrement vdpptr2; break if 0
    lda vdpptr2
    bne :+
    dec vdpptr2 + 1
:   dec vdpptr2
    lda vdpptr2
    ora vdpptr2 + 1
    beq @done
    inc16 vdpptr1
    bra @loop
@done:
    rts

.rodata
str_tab: .byte "    ",0
textmode_registers:
    .byte $00, $00  ; textmode, no external video
    .byte $d0, $01  ; 16K, enable display, disable interrupt
    .byte $02, $02  ; name table at 0x0800
    .byte $00, $04  ; pattern table at 0x0000
    .byte $f4, $07  ; white text on dark blue background
    .byte $ff       ; end of data table

