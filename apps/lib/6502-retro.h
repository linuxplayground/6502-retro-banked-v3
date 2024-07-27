#include <stdint.h>
//
// ACIA
//

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
 *
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
extern void sn_beep();


//
// VDP
//

extern void vdp_clear_screen();
extern void vdp_80_col();
extern void __fastcall__ vdp_print(const char * s);
extern void __fastcall__ vdp_write_char(unsigned char c);
extern void vdp_init_textmode();
extern void vdp_init_g2mode();
extern void vdp_unlock();
extern void vdp_load_font_wrapper(const unsigned char * font, unsigned int size);
extern void __fastcall__ vdp_write_reg(unsigned int val);
extern void __fastcall__ vdp_write_address(unsigned int addr);
extern void vdp_newline();
extern void __fastcall__ vdp_console_out(const char s);
extern void vdp_flush();

extern unsigned char vdpptr1;
extern unsigned char vdpptr2;
extern unsigned char screenbuf[0x300];

#define VDP_DAT *(char*) 0x9F30
#define VDP_REG *(char*) 0x9F31

struct __sVdp {
    uint16_t nametable;
    uint16_t colortable;
    uint16_t patterntable;
    uint16_t spriteattributetable;
    uint16_t spritepatterntable;
    uint8_t cols;
    uint8_t rows;
    uint8_t vx;
    uint8_t vy;
    uint8_t tick;
    uint8_t status;
};

#define VDP  (*(volatile struct __sVdp *)0xB500)

/*
* Wait for the next VBLANK interrupt.
*/
void vdp_wait() {
    while ((VDP.tick & 0x80) == 0) {;;}
    VDP.tick = 0;
}

//
// GENERAL
//

void delay(uint16_t frames) {
    while (frames > 0) {
        vdp_wait();
        --frames;
    }
}


