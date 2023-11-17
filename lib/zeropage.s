.include "zeropage.inc"
.zeropage
; C
sp:                     .res 2  ; 0
sreg:                   .res 2  ; 2
regsave:                .res 4  ; 4
ptr1:                   .res 2  ; 8
ptr2:                   .res 2  ; a
ptr3:                   .res 2  ; c
ptr4:                   .res 2  ; e
tmp1:                   .res 1  ; 10
tmp2:                   .res 1  ; 11
tmp3:                   .res 1  ; 12
tmp4:                   .res 1  ; 13
regbank:                .res 6  ; 14
tmpstack:               .res 1  ; 1a
; Console Buffer indexes
con_r_idx:              .res 1  ; 1b
con_w_idx:              .res 1  ; 1c
; bank variables
imparm:                 .res 2  ; $1d
                                ; end at $1e

ram_bank:               .res 1  ; $21
rom_bank:               .res 1  ; $22
; ; sdcard
; sdptr:                  .res 2  ; $24
; ; dos
; fat32_ptr:              .res 2  ; $26
; fat32_ptr2:             .res 2  ; $28
; fat32_bufptr:           .res 2  ; $2A
; fat32_lfn_bufptr:       .res 2  ; $2C