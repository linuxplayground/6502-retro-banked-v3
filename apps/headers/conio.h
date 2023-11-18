#ifndef CONIO_H
#define CONIO_H

extern unsigned char cgetc();
extern void __fastcall__ cputc(const unsigned char c);
extern void __fastcall__ cputs(const char * s);
extern unsigned char cgetc_nw();

#endif