#include "main.h"
int main() {
    char c;
    acia_puts("\r\nHello, World!\r\n");
    beep();
    while (c != 0x1b) {
      c = acia_getc();
      acia_putc(c); 
    }
    return 0;
}
