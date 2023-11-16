.include "sysram.inc"
.include "acia.inc"
.include "zeropage.inc"
.import         popax, popptr1

.export _cgetc, _cputc, _cputs, _cgetc_nw, _write, strNewLine


.rodata
strNewLine: .byte $0a, $0d, $00

.code
; C Compliant: returns a key in A.  Waits for a keypress.
; preserves Y
_cgetc:
        phx
:
        lda     con_r_idx
        cmp     con_w_idx
        beq     :-
        tax
        lda     con_buf,x
        inc     con_r_idx
        sec
        plx
        rts

; C Compliant: writes A.  Passes to _acia
_cputc:
        jmp     _acia_putc

; C Compliant: Writes 0 terminated string < 255 chard long pointed to by XA to _acia
_cputs:
        jmp     _acia_puts

; C Compliant, .C. is clear if no data, .A. is 0 if no data otherwise .C. is
; set and A is value.
_cgetc_nw:
        phx
        sei
        lda     con_r_idx
        cmp     con_w_idx
        cli
        beq     @no_data
        tax
        lda     con_buf,x
        inc     con_r_idx
        sec
        plx
        rts
@no_data:
        clc
        lda #0
        plx
        rts

;
; int __fastcall__ write (int fd, const void* buf, int count);
;
_write:
        sta     ptr3
        stx     ptr3+1          ; Count in ptr3
        inx
        stx     ptr2+1          ; Increment and store in ptr2
        tax
        inx
        stx     ptr2
        jsr     popptr1         ; Buffer address in ptr1
        jsr     popax

begin:  dec     ptr2
        bne     outch
        dec     ptr2+1
        beq     done

outch:  ldy     #0
        lda     (ptr1),y
        pha                     ; Save A (changed by OUTCHR)
        jsr     _cputc          ; Send character using Monitor call
        pla                     ; Restore A
        cmp     #$0A            ; Check for '\n'
        bne     next            ; ...if LF character
        lda     #$0D            ; Add a carriage return
        jsr     _cputc

next:   inc     ptr1
        bne     begin
        inc     ptr1+1
        jmp     begin

done:   lda     ptr3
        ldx     ptr3+1
        rts                     ; Return count