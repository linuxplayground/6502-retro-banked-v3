; vim: ft=asm_ca65
ram_bank        = $13
rom_bank        = $14
krn_ptr1        = $15

acia_init       = $FF00 
acia_getc       = $FF03 
acia_getc_nw    = $FF06 
acia_putc       = $FF09 
acia_puts       = $FF0C 
prbyte          = $FF0F 
sn_beep         = $FF75
primm           = $FF15 

sn_start        = $FF6C
sn_stop         = $FF6F
sn_silence      = $FF72
sn_send         = $FF84
