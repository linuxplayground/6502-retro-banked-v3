MONITOR_BANK = $00
BASIC_BANK   = $01

jsrfar3    = $0200 ; jsrfar: RAM part
jmpfr      = $021F ; jsrfar: core jmp instruction
rstfar     = $0222 ; hard jump to different bank
imparm     = $19   ; jsrfar: temporary byte
