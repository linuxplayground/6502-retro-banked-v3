#include "6502-retro.h"
#include "font80.h"

void init() {
    vdp_unlock();
    vdp_init_textmode();
    vdp_80_col();
    vdp_clear_screen();
    vdp_load_font_wrapper(font80, 0x0400);
    vdp_write_address(0x0800);
    vdp_print("Conways Game Of Life");
    vdp_newline();
    vdp_write_char('>');
    acia_puts("Conways Game Of Life\n\r :>");
}

unsigned char c;

void main() {
    c = 0;

   vdp_unlock();
   vdp_init_textmode();
   vdp_80_col();
   vdp_clear_screen();
   vdp_load_font_wrapper(font80, 0x0400);

   VDP_REG = 0x61;
   VDP_REG = 0x87;

   vdp_write_address(0x0800);
   vdp_print("Conways Game Of Life");
   vdp_newline();
   vdp_write_char('>');
   acia_puts("Conways Game Of Life\n\r :>");

    c=0;
    while (c != 0x1b) {
        c = acia_getc_nw();
        if (c > 0x1f) vdp_console_out(c);
        else if (c == 0x07) {
              beep();
              acia_puts("BEEP\r\n");
        }
        else if (c == 0x03) break;
    }
    vdp_newline();
    vdp_print("Exiting...");
    acia_puts("Exiting...\r\n");
}
