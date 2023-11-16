.include "sysram.inc"
.segment "SYSRAM"
con_buf:                        .res $0100      ;200
sector_buffer:                  .res 512
sector_buffer_end:
sector_lba:                     .res 4
wozmon_buf:                     .res $007F      ;30F
jmpfr:                          .res 3