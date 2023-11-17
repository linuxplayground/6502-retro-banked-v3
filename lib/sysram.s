.include "sysram.inc"
.segment "SYSRAM"
con_buf:                        .res $0100      ;200
sd_cmd_buf:                     .res 6, 0
sdcard_param:                   .res 1
sector_lba:                     .res 4 ; dword (part of sdcard_param) - LBA of sector to read/write
                                .res 1

wozmon_buf:                     .res $007F

xstart:                         .res 2  ; holds the start address from xmodem
xend:                           .res 2  ; holds the address of the last byte from xmodem

.segment "KERNALRAM2"
sector_buffer:                  .res 512
sector_buffer_end: