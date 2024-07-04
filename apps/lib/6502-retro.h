#include <peekpoke.h>

/* Print a string to serial pointed to by s
 */
extern void acia_puts(const char * s);

/* Wait for a character on the serial port.  Blocking wait.
 */
extern unsigned char acia_getc();

/* Check if serial port has a character waiting
 */
extern unsigned char acia_getc_nw();

/* Print a single character `c` to the serial port.
 */
extern void __fastcall__ acia_putc(const unsigned char c);

/* Print the hex representation of a single byte given by c
 * to the serial port
 */
extern void __fastcall__ prbyte(const unsigned char c);

//
// SOUND
//

/* Generate a short beep on the speaker
 */
extern void beep();

//
// VDP
//

extern void vdp_clear_screen();
extern void vdp_80_col();
extern void __fastcall__ vdp_print(const char * s);
extern void __fastcall__ vdp_write_char(unsigned char c);
extern void vdp_init_textmode();
extern void vdp_unlock();
extern void vdp_load_font_wrapper(const char * font, unsigned int size);
extern void __fastcall__ vdp_write_address(unsigned int addr);
extern void vdp_newline();
extern void __fastcall__ vdp_console_out(const char s);

extern unsigned char vdpptr1;
extern unsigned char vdpptr2;

#define VDP_DAT *(char*) 0x9F30
#define VDP_REG *(char*) 0x9F31

