; vim: ft=asm_ca65
DOS_BANK     = $00
BASIC_BANK   = $01
HOPPER_BANK  = $02

jsrfar3    = $0200 ; jsrfar: RAM part
jmpfr      = $021F ; jsrfar: core jmp instruction
rstfar     = $0222 ; hard jump to different bank
imparm     = $17   ; jsrfar: temporary byte
