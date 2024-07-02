; vim: ft=asm_ca65
.include "../../rom/inc/kern.inc"
.include "../../rom/inc/io.inc"

SN_WE   = %00000100
SN_READY= %00001000

FIRST   = %10000000
SECOND  = %00000000
CHAN_1  = %00000000
CHAN_2  = %00100000
CHAN_3  = %01000000
CHAN_N  = %01100000
TONE    = %00000000
VOL     = %00010000
VOL_OFF = %00001111
VOL_MAX = %00000000

C1_SUSTAIN  = $F0
C1_DECAY    = $F1

FULL        = 64
HALF        = 32
QUARTER     = 16
EIGHTH      = 8
SIXTEENTH   = 4
THIRTYTOOTH = 2

TMPKEY      = $F4

.code
        jsr init_via_ports
        ; Set up T1 timer in continuous interrupts mode for 50hz
        lda #%01000000
        sta via_acr 
        ; Clock is 2mhz so 40hz is 50000 cycles
        ; need to subtract 2 for the loop
        lda $4e
        sta via_t1cl
        lda $c3
        sta via_t1ch

        lda #<welcome
        ldx #>welcome
        jsr acia_puts

gameloop:
        jsr acia_getc
        cmp #$1b
        beq end

        sta TMPKEY

        ldx #0
@find_key_lp:
        lda keys,x
        cmp TMPKEY
        beq @found
        inx
        cpx #12
        bne @find_key_lp
        jmp gameloop            ; not found
@found:
        lda keynotes,x
        jsr play_note
        ldy #6
        jsr decay
        jmp gameloop
end:
        jsr silence_all
        rts

time:
        lda #%01000000
wait_for_40hz:
        bit via_ifr
        beq wait_for_40hz
        lda via_t1cl
        dex
        bne time
        rts

; note index in A
play_note:
        tax
        lda notes,x
        ora #(FIRST|CHAN_1|TONE)
        jsr sn_send
        inx
        lda notes,x
        ora #(SECOND|CHAN_1|TONE)
        jsr sn_send
        lda #(FIRST|CHAN_1|VOL|$04)
        jsr sn_send
        rts

decay:
        ldx #$04        ; match starting volume
        sty $F0

        lda #$D2        ; decay interval
        sta via_t1cl
        lda #$30
        sta via_t1ch

@loop:
        ldy $F0
        txa
        ora #(FIRST|CHAN_1|VOL)
        jsr sn_send
        lda #%01000000
@wait:
        bit via_ifr
        beq @wait
        lda via_t1cl
        dey
        bne @wait
        inx     
        cpx #$10
        bne @loop

        lda $4e         ; reset timer to standard
        sta via_t1cl
        lda $c3
        sta via_t1ch
        rts

silence_all:
        lda #(FIRST|CHAN_1|VOL|VOL_OFF)
        jsr sn_send
        lda #(FIRST|CHAN_2|VOL|VOL_OFF)
        jsr sn_send
        lda #(FIRST|CHAN_3|VOL|VOL_OFF)
        jsr sn_send
        lda #(FIRST|CHAN_N|VOL|VOL_OFF)
        jsr sn_send
        rts

; Send a byte of data to the SN
; clobbers A
sn_send:
    sta via_portb          ; Put our data on the data bus
    lda via_porta          ; get existing IO byte control
    eor #SN_WE         ; toggle SN_WE (HIGH to LOW)
    sta via_porta          ; save
    jsr wait_ready     ; wait for SN to be ready
    lda via_porta          ; get existing IO byte (wait_ready broke A)
    eor #SN_WE         ; toggle SN_WE (LOW to HIGH)
    sta via_porta          ; save
    rts

; Wait for the SN76489 to signal it's ready for more commands
wait_ready:
    lda via_porta
    and #SN_READY
        bne wait_ready
ready_done:
    rts

; set up IO Byte on VIA_via_porta
init_via_ports:
        lda via_ddra        ; enable SN_WE pin for output, preserve existing
        ora #SN_WE
        sta via_ddra
        lda #%11111111  ; all of via_portb is output.
        sta via_ddrb
        lda via_porta       ; Start with a high on SN_WE
        ora #SN_WE
        sta via_porta
        rts
.rodata 
welcome:
    .byte 12
    .byte "Play the piano, Keys are Rows A for notes and Q for sharp notes."
    .byte $0a,$0d,"Escape to quit."
    .byte $0a, $0d, 0
keys:
    ;      C  C#   D   D#  E   F  F#   G   G#  A   A#  B 
    .byte "a","w","s","e","d","f","t","g","y","h","u","j"
keynotes:
    ;      C  C#  D   D#  E   F   F#   G   G#  A   A#  B 
    .byte $48,$4a,$4c,$4e,$50,$52,$54,$56,$58,$5a,$5c,$5e 

.include "notes.asm"
