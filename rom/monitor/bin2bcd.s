; vim: ft=asm_ca65
; Converts fat32_size into binary encoded decimal

.import sfs_bytes_rem
.import FORMAT_BUF
.export BinToBcd

.code
BinToBcd:
;Convert binary number to BCD. 
;Arbitrary number sizes are supported.
;In:
;   fat32_size    buffer with number to convert
;   a      number of bytes in the number
;Out:
;   FORMAT_BUF   output buffer
;  a            number of BCD bytes (at least 1)
;Uses:
;   x,y, t1,t1_h, t2


        ldx #0         ; initial result is 0, 1 byte size
        stx FORMAT_BUF
        inx
        stx bcd_size

    ;---Skip leading zeroes in the number (this may be removed, it we need the routine smaller)
        tay
        iny
skip:   dey
        beq done         ;the number is zero, we are done
        lda sfs_bytes_rem-1,y
        beq skip

        sty num_size
        sed

    ;--- Process one byte at a time
next_byte:
        ldy num_size
        lda sfs_bytes_rem-1,y      
        sta b
        sec            ;set top bit of the mask to 1
        bcs loop      

shift_byte:
    ;--- BCD = BCD * 2 + CARRY
        ldy #1
        ldx bcd_size
mul2:
        lda FORMAT_BUF-1,y
        adc FORMAT_BUF-1,y
        sta FORMAT_BUF-1,y
        iny
        dex
        bne mul2
        
        bcc loop
        
    ;--- BCD must be one byte bigger (we need to store our extra 1 in CARRY there)
        lda #1
        sta FORMAT_BUF-1,y
        sty bcd_size         ;as the x is 1 based, we can directly store is as new bcd_size
                                ;we cound use INC here, it would be slower, however.
        clc
loop:   rol b               ;Divide by two, if result is 0, end. As we initially set the 0 bit to 1, this is in fact loop to 8.
        bne shift_byte

    ;--- Repeat for all bytes in the number
        dec num_size
        bne next_byte
                        
        cld
done:
        lda bcd_size
        rts

.segment "BSS"
bcd_size:       .byte 0
num_size:       .byte 0
b:              .byte 0
