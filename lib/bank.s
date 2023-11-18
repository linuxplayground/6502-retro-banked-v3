
; bank switch call code JSFAR
; copied from : https://github.com/commanderx16/x16-rom/blob/master/inc/jsrfar.inc
; ; (C)2019 Michael Steil, License: 2-clause BSD

; jsr   jsrfar
; .word _conin
; .byte KERNALROM
; next instruction
.include "zeropage.inc"
.include "sysram.inc"
.export jsfar, rstfar, rambankreg, rombankreg

BANK_BASE = $9F00
rambankreg = BANK_BASE + 0
rombankreg = BANK_BASE + 1

; XXX
; jmpfr is defined as 3 reserved bytes in sysram.s.  The main rom routine sets the first 
; byte to the JMP INDIRECT OPCODE.  This could be an issue if we expect it to be a regular
; indirect.
; JMP INDIRECT (6C) was chosen to maintain compatibilty with the vector jump table ROM BANK 0 in
; page FF.
; XXX


.segment "KERNRAM"
; this routine will save registers and navigate the stack to find the target indrect jump
; location and desired bank.  Once found, it will update the jmpfar argument, write the bank register
; depenging on if it's to ram or rom and finally jmp to that location.
; on return, the routine will reset the stack and the registeres etc before returning to the caller.

jsfar:
	pha             ;reserve 1 byte on the stack
	php             ;save registers & status    
	pha             
	phx             
	phy             

        tsx
	lda 	$106,x      ;return address lo
	sta 	imparm
	clc
	adc 	#3
	sta 	$106,x      ;and write back with 3 added
	lda 	$107,x      ;return address hi
	sta 	imparm+1
	adc 	#0
	sta 	$107,x

	ldy     #1
	lda     (imparm),y  ;target address lo
	sta     jmpfr+1     ; jmp LL HH (This is the LL part of self modifying code.)
	iny     
	lda     (imparm),y  ;target address hi
	sta     jmpfr+2     ; jmp LL HH (This is the HH part of the self modifying code.)
	cmp     #$c0
	bcc     jsrfar1     ;target is in RAM
; target is in ROM
	lda     rom_bank
	sta     $0105,x     ;save original bank into reserved byte
	iny     
	lda     (imparm),y  ;target address bank
	ply                 ;restore registers
	plx     
	jmp     jsrfar3

; target is in RAM
jsrfar1:
	lda     ram_bank
	sta     $0105,x         ;save original bank into reserved byte
	iny
	lda     (imparm),y      ;target address bank
	sta     BANK_BASE + 0        ;set RAM bank
	ply                     ;restore registers
	plx
	pla
	plp
	jsr     jmpfr
	php
	pha
	phx
	tsx
	lda     $0104,x
	sta     BANK_BASE + 0    ;restore RAM bank
jsrfar2:
	lda     $0103,x     ;overwrite reserved byte...
	sta     $0104,x     ;...with copy of .p
	plx
	pla
	plp
	plp
	rts
jsrfar3:
        sta     BANK_BASE + 1 ;set ROM bank
	pla
	plp
	jsr     jmpfr
	php
	pha
	phx
	tsx
	lda     $0104,x
	sta     BANK_BASE + 1    ;restore ROM bank
	lda     $0103,x     ;overwrite reserved byte...
	sta     $0104,x     ;...with copy of .p
	plx
	pla
	plp
	plp
	rts

; set the rom bank and reset
; resets ram bank too
rstfar:
	sta	BANK_BASE + 1
	sta	rom_bank
	stz	BANK_BASE + 0
	sta	ram_bank
rom_reset:
	jmp ($FFFC)	     ; do a hard reset to whatever is defined in this rom.

jmpfr:  .res 3