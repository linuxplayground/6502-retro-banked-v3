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
.import sn_start, sn_stop, sn_silence, sn_beep, sn_play_note, sn_play_noise, sn_env_note, sn_env_noise, sn_send
.import _vdp_80_col, _vdp_unlock, _vdp_lock, _vdp_print, _vdp_clear_screen
.import _vdp_init_textmode, _vdp_init_g2mode, _vdp_write_reg, _vdp_write_address, _vdp_load_font
.import _vdp_newline, _vdp_write_char, _vdp_console_out, _vdp_flush

.segment "JMPTBL"

jmp acia_init
jmp acia_getc
jmp acia_getc_nw
jmp acia_putc
jmp acia_puts
jmp prbyte
nop     ;; reserve a slot here.  sn_beep moving to end of list
nop
nop
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
jmp _vdp_80_col
jmp _vdp_unlock
jmp _vdp_lock
jmp _vdp_print
jmp _vdp_clear_screen
jmp _vdp_init_textmode
jmp _vdp_write_reg
jmp _vdp_write_address
jmp _vdp_load_font
jmp _vdp_newline
jmp _vdp_write_char
jmp _vdp_console_out
jmp sn_start
jmp sn_stop
jmp sn_silence
jmp sn_beep
jmp sn_play_note
jmp sn_play_noise
jmp sn_env_note
jmp sn_env_noise
jmp sn_send
jmp _vdp_init_g2mode
jmp _vdp_flush
