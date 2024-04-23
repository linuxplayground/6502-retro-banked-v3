; vim: ft=asm_ca65
.import acia_init, acia_getc, acia_getc_nw, acia_putc, acia_puts
.import prbyte, primm
.import sfs_init                  
.import sfs_mount                 
.import sfs_open_first_index_block
.import sfs_create                
.import sfs_find                  
.import sfs_read_next_index       
.import sfs_write                 
.import sfs_read                  
.import sfs_delete                
.import sfs_format                
.import sfs_open                  
.import sfs_close                 
.import sfs_read_byte             
.import sfs_write_byte    
.import sdcard_init 
.import dos_bdir
.import sn_beep
.import vdp_init, vdp_write_register, vdp_set_write_address, vdp_set_read_address
.import vdp_clear_vram, vdp_load_font, vdp_enable_text_80_mode
.segment "JMPTBL"

jmp acia_init
jmp acia_getc
jmp acia_getc_nw
jmp acia_putc
jmp acia_puts
jmp prbyte
jmp sn_beep
jmp primm
jmp sfs_init
jmp sfs_mount
jmp sfs_open_first_index_block
jmp sfs_create                
jmp sfs_find                  
jmp sfs_read_next_index       
jmp sfs_write                 
jmp sfs_read                  
jmp sfs_delete                
jmp sfs_format                
jmp sfs_open                  
jmp sfs_close                 
jmp sfs_read_byte             
jmp sfs_write_byte            
jmp sdcard_init
jmp dos_bdir
jmp vdp_init
jmp vdp_write_register
jmp vdp_set_write_address
jmp vdp_set_read_address
jmp vdp_clear_vram
jmp vdp_load_font
jmp vdp_enable_text_80_mode
