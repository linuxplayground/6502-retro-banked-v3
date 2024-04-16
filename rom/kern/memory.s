; vim: ft=asm_ca65
.include "io.inc"
.include "banks.inc"

.globalzp ram_bank, rom_bank

.export jsrfar, init_ram
.code

jsrfar:
.include "jsrfar.inc"

.import __KERNRAM_LOAD__, __KERNRAM_RUN__, __KERNRAM_SIZE__
; copy banking code into RAM
;
init_ram:
	ldx #<__KERNRAM_SIZE__
:	lda __KERNRAM_LOAD__-1,x
	sta __KERNRAM_RUN__-1,x
	dex
	bne :-
	rts

;/////////////////////   K E R N A L   R A M   C O D E  \\\\\\\\\\\\\\\\\\\\\\\

.segment "KERNRAM"
.export jmpfr, rstfar
.assert * = jsrfar3, error, "jsrfar3 must be at specific address"
;jsrfar3:
	sta rombankreg    ;set ROM bank
	pla
	plp
	jsr jmpfr
	php
	pha
	phx
	tsx
	lda $0104,x
	sta rombankreg    ;restore ROM bank
	sta rom_bank      ;save to register
	lda $0103,x     ;overwrite reserved byte...
	sta $0104,x     ;...with copy of .p
	plx
	pla
	plp
	plp
	rts
.assert * = jmpfr, error, "jmpfr must be at specific address"
;jmpfr:
__jmpfr:
	jmp $ffff

.assert * = rstfar, error, "rstfar must be at specific address"
;rstfar:
	sta rom_bank
	sta rombankreg
	jmp ($FFFC)

