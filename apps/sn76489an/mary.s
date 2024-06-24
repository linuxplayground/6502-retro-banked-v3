; vim: ft=asm_ca65
; synth.s - Playing with the SN76489AN chip

; SN76489AN - https://www.smspower.org/Development/SN76489
; Data formats
; LCCTDDDD
; Latch indicator
; Channel
; Register type (0=tone, 1=volume)
; Data
; 1CCTDDDD (latch byte)
; 0-DDDDDD (data byte)
FIRST           = %10000000
SECOND          = %00000000
CHANNEL_1       = %00000000
CHANNEL_2       = %00100000
CHANNEL_3       = %01000000
CHANNEL_NOISE   = %01100000
TONE            = %00000000
VOLUME          = %00010000
VOLUME_OFF      = %00001111
VOLUME_MAX      = %00000000

; Some notes
C5_BYTE_1       = $07
C5_BYTE_2       = $07
D5_BYTE_1       = $0a
D5_BYTE_2       = $06
E5_BYTE_1       = $0E
E5_BYTE_2       = $05
G5_BYTE_1       = $0F
G5_BYTE_2       = $04

; 6522 VIA
PORTB = $9F20
PORTA = $9F21
DDRB  = $9F22
DDRA  = $9F23

; SN76489AN
SN_READY        = %00001000
SN_WE           = %00000100     ; Write enable pin (active low)

; Our address decoder has the ROM at $8000
.code
reset:
    LDA #%10000110          ; CE and WE pins to output, READY to input
    STA DDRA
    LDA #%11111111          ; Default to setting the SN data bus to output
    STA DDRB

    ; Initialize the SN76489
    LDA #%00000100          ; Set CE low (inactive), WE high (inactive)
    STA PORTA

    JSR silence_all
    JSR sleep
    JSR sleep

    ; Play Mary Had a Little Lamb located, array at $E000
    LDX #$00                ; Index into our song array
play_song:
    INX
	LDA song,X             ; Load the first byte of the note
    INX
	LDY song,X             ; Load the second byte of the note
    JSR play_note
	;jsr minisleep
	CPX song; Have we played all the notes?
    BEQ song_done
    JMP play_song
	jsr silence_all
song_done:
	jsr silence_all
    JMP stop

; Sleep forever
stop:
	rts

; Register A first byte of note
; Register Y second byte of note
play_note:
    ORA #(FIRST|CHANNEL_1|TONE)
    JSR sn_send
    TYA
    ORA #(SECOND|CHANNEL_1|TONE)
    JSR sn_send
    LDA #(FIRST|CHANNEL_1|VOLUME|VOLUME_MAX)
    JSR sn_send
    LDA #(SECOND|CHANNEL_1|VOLUME|VOLUME_MAX)
    JSR sn_send
    JSR sleep
    ;JSR silence_all
    RTS

minisleep:
	phx
	phy
	ldx #$0f
ms1:
	ldy #0
ms2:
	dey
	bne ms2
	dex
	bne ms1
	ply
	plx
	rts

silence_all:
    PHA
    LDA #(FIRST|CHANNEL_1|VOLUME|VOLUME_OFF)
    JSR sn_send
    LDA #(SECOND|%00111111)
    JSR sn_send
    LDA #(FIRST|CHANNEL_2|VOLUME|VOLUME_OFF)
    JSR sn_send
    LDA #(SECOND|%00111111)
    JSR sn_send
    LDA #(FIRST|CHANNEL_3|VOLUME|VOLUME_OFF)
    JSR sn_send
    LDA #(SECOND|%00111111)
    JSR sn_send
    LDA #(FIRST|CHANNEL_NOISE|VOLUME|VOLUME_OFF)
    JSR sn_send
    PLA
    RTS

; A - databus value to strobe SN with
sn_send:
    PHX
    STA PORTB               ; Put our data on the data bus
    LDX #%00000100          ; Strobe WE
    STX PORTA
    LDX #%00000000          
    STX PORTA
    JSR wait_ready          ; Wait for chip to be ready from last instruction
    LDX #%00000100
    STX PORTA
    PLX
    RTS

; Wait for the SN76489 to signal it's ready for more commands
wait_ready:
	PHA
ready_loop:
    LDA PORTA
    AND #SN_READY
    BNE ready_loop
ready_done:
    PLA
    RTS

sleep:
    PHX
    PHY
    LDY #$00
    LDX #$00
sleep2:
    CPX #$FF
    BEQ sleep2b
    INX
    JMP sleep2
sleep2b:
    CPY #$FF
    BEQ sleep_done
    INY
    LDX #$00
    JMP sleep2
sleep_done:
    PLY
    PLX
    RTS

    ; Song: first verse of Mary had a Little Lamb
    ; https://www.true-piano-lessons.com/mary-had-a-little-lamb.html
    ; TODO: Add length of each note
	.rodata 
song:
    .byte $34                 ; 26 notes in this array
    .byte E5_BYTE_1,E5_BYTE_2 ; M
    .byte D5_BYTE_1,D5_BYTE_2 ; ry
    .byte C5_BYTE_1,C5_BYTE_2 ; had
    .byte D5_BYTE_1,D5_BYTE_2 ; a
    .byte E5_BYTE_1,E5_BYTE_2 ; lit-
    .byte E5_BYTE_1,E5_BYTE_2 ; tle
    .byte E5_BYTE_1,E5_BYTE_2 ; lamb
    .byte D5_BYTE_1,D5_BYTE_2 ; lit-
    .byte D5_BYTE_1,D5_BYTE_2 ; tle
    .byte D5_BYTE_1,D5_BYTE_2 ; lamb
    .byte E5_BYTE_1,E5_BYTE_2 ; lit-
    .byte G5_BYTE_1,G5_BYTE_2 ; tle
    .byte G5_BYTE_1,G5_BYTE_2 ; lab
    .byte E5_BYTE_1,E5_BYTE_2 ; Ma
    .byte D5_BYTE_1,D5_BYTE_2 ; ry
    .byte C5_BYTE_1,C5_BYTE_2 ; had
    .byte D5_BYTE_1,D5_BYTE_2 ; a
    .byte E5_BYTE_1,E5_BYTE_2 ; lit-
    .byte E5_BYTE_1,E5_BYTE_2 ; tle
    .byte E5_BYTE_1,E5_BYTE_2 ; lamb
    .byte E5_BYTE_1,E5_BYTE_2 ; its
    .byte D5_BYTE_1,D5_BYTE_2 ; fleece
    .byte D5_BYTE_1,D5_BYTE_2 ; was
    .byte E5_BYTE_1,E5_BYTE_2 ; white
    .byte D5_BYTE_1,D5_BYTE_2 ; as
    .byte C5_BYTE_1,C5_BYTE_2 ; snow
