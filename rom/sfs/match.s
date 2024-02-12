; vim: ft=asm_ca65
.include "structs.inc"
.import sector_buffer, sector_buffer_end, index
.globalzp sfs_fn_ptr

.export match_name, to_lower

.bss
char_tmp:              .byte 0

.code

;-----------------------------------------------------------------------------
; match_name
;
; Check if name matches
;
; In:   sfs_fn_ptr  name
;       y           name offset
; Out:  c           =1: matched
;-----------------------------------------------------------------------------
match_name:
	ldx #0
	ldy #0
@1:	lda (sfs_fn_ptr), y
	beq @match
	cmp #'/'
	beq @match
	cmp #'?'
	beq @char_match
	cmp #'*'
	beq @asterisk
	jsr to_lower
	sta char_tmp
	lda index + sIndex::filename, x
	jsr to_lower
	cmp char_tmp
	beq @char_match
	bne @no
@char_match:
	inx
	iny
	bra @1

; '*' found: consume excess characters in input until '/' or end
@asterisk:
	iny
	lda (sfs_fn_ptr), y
	beq @yes
	cmp #'/'
	bne @asterisk
	bra @yes

@match:	; Search string also at end?
	lda index + sIndex::filename, x
	bne @no

@yes:
	sec
	rts
@no:
	clc
	rts

;-----------------------------------------------------------------------------
; to_lower
;-----------------------------------------------------------------------------
to_lower:
	; Lower case character?
	cmp #'A'
	bcc @done
	cmp #'Z'+1
	bcs @done

	; Make lowercase
	ora #$20
@done:	rts
