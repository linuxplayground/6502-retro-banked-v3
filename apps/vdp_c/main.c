#include "6502-retro.h"
#include "font80.h"

char c;

void main() {
    c = 0;

    vdp_unlock();
    vdp_init_textmode();
    vdp_80_col();
    vdp_clear_screen();
    vdp_load_font_wrapper(font80, 0x0400);

    vdp_write_address(0x0800);
    vdp_print("Hello, World from VDP C application!");
    vdp_newline();
    vdp_print("Press ESC to exit.");
    vdp_newline();
    vdp_print("> ");
    while (1) {
        c = acia_getc();
        if (c == 0x1b) break;
        vdp_console_out(c);
    }
}
