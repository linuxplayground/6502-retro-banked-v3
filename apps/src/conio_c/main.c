#include <stdio.h>
#include "conio.h"

unsigned char c;
extern unsigned char bank;

unsigned char main(void) {

        cputs("Hello, conio from C\n\r");
        printf("Hello, %02X from printf.\n\r", 0xaa);
        while (c!=0x1b) {
                c = cgetc();
                if (c >= 0x30 && c<=0x39)
                        bank = c - 0x30;
                if (c == 0x0d) {
                        cputc(0x0a);
                }
                cputc(c);
        }
        return 0;
}