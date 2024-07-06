#include "6502-retro.h"

unsigned char c;

int main() {
    c = 0;
    acia_puts("\r\nHello, World!\r\n");
    sn_beep();
    while (c != 0x1b) {
      c = acia_getc();
      acia_putc(c); 
    }

    return 0;
}
