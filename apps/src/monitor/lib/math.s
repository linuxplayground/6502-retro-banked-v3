.include "zeropage.inc"
.import _prbyte

.export bin2bcd16, hex_str_to_byte


.code
bin:                    .res 2
bcd:                    .res 3

; convert binary data stored in BIN (2 byes) into BCD data stored in BCD
; also prints the results
bin2bcd16:
        sei
        sed

        sta     bin
        stx     bin+1
        stz     bcd
        stz     bcd + 1
        stz     bcd + 2
        ldx     #16
@cnvbit:
        asl     bin + 0
        rol     bin + 1
        lda     bcd + 0
        adc     bcd + 0
        sta     bcd + 0
        lda     bcd + 1
        adc     bcd + 1
        sta     bcd + 1
        lda     bcd + 2
        adc     bcd + 2
        sta     bcd + 2
        dex
        bne     @cnvbit

        cld
        cli

        lda     bcd + 2
        jsr     _prbyte
        lda     bcd + 1
        jsr     _prbyte
        lda     bcd + 0
        jsr     _prbyte

        rts

; A = high nibble, X = low nibble
; result in A
hex_str_to_byte:
        jsr     @asc_hex_to_bin          ; convert to number - result is in A
        asl                            ; shift to high nibble
        asl
        asl
        asl
        sta     tmp1                    ; and store
        txa                             ; get the low nibble character
        jsr     @asc_hex_to_bin          ; convert to number - result is in A
        ora     tmp1                    ; OR with previous result
        rts

@asc_hex_to_bin:                        ; assumes ASCII char val is in A
        sec
        sbc     #$30                    ; subtract $30 - this is good for 0-9
        cmp     #10                     ; is value more than 10?
        bcc     @asc_hex_to_bin_end      ; if not, we're okay
        sbc     #$07                    ; otherwise subtract another $07 for A-F
@asc_hex_to_bin_end:
        rts                             ; value is returned in A