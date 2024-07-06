#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "6502-retro.h"
#include "font80.h"

uint8_t k;
uint16_t addr;
uint8_t counter;
uint16_t counter_val;
uint8_t tb[40];

uint8_t working[0x960];
uint8_t screen_buf[0x960];
uint16_t i;
uint8_t ch;
uint16_t seed;
uint8_t x, y;
uint8_t blk;

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

void char_at_xy(uint8_t x, uint8_t y, uint8_t c) {
    addr = 0x800 + (y*80 + x);
    vdp_write_address(addr);
    VDP_DAT = c;
}

void print_at_xy(uint8_t x, uint8_t y, const char * s) {
    addr = 0x800 + (y*80) + x;
    vdp_write_address(addr);
    do {
        VDP_DAT = *s;
        ++s;
    } while (*s != 0);
}

/*
 * stream screen_buf to the nametable
*/
void flush() {
    vdp_write_address(0x800);
    i = 0;
    do {
        VDP_DAT = screen_buf[i];
        ++i;
    } while (i < 0x800 + 0x960);
}


void main() {
    k = 0;
    counter = 0;
    counter_val = 0;
    blk = 0x1d;

    vdp_unlock();
    vdp_init_textmode();
    vdp_80_col();

    memset(screen_buf, 0x20, 0x960);
    vdp_load_font_wrapper(font80, 0x0400);

    vdp_write_reg(0x07B1); //Write 0x61 to register 7
    vdp_write_reg(0x01f0); //Write 0xE0 to register 1 (enable interrupts)
    vdp_wait();
    flush();
    print_at_xy(0,23,"Conway;s game of life: Press a key to start.");

    seed = 0;

    while (acia_getc_nw() == 0) {
        ;;
    }
    do {
        ++seed;
        counter = 0;
        srand(seed);
        memset(screen_buf, 0x20, 0x20);
        for (i=0; i<0x960; ++i) {
            if ( (rand() % 100) < 50) {
                screen_buf[i] = blk;
            }
        }
        vdp_wait();
        flush();

        while (counter < 84) {
            memset(working, 0, 0x960);
            for (y=0; y<24; ++y) {
                for (x=0; x<79; ++x) {
                    i = y*80+x;
                    if (screen_buf[i] == blk) {
                        if (y>0) {
                            working[i-81] ++;
                            working[i-80] ++;
                            working[i-79] ++;
                        }

                        if (y<23) {
                            working[i+79] ++;
                            working[i+80] ++;
                            working[i+81] ++;
                        }

                        if (x>0) {
                            working[i-1] ++;
                        }

                        if (x<79) {
                            working[i+1] ++;
                        }
                    }
                }
            }
            for (i=0; i<0x960; ++i) {
                if (working[i] == 3 && screen_buf[i] == ' ') {
                    screen_buf[i] = blk;
                } else if (working[i] < 2 || working[i] > 3) {
                    screen_buf[i] = ' ';
                }
            }
            ++counter;
            //vdp_wait();
            //vdp_wait();
            flush();
            ch = acia_getc_nw();
            if (ch == 'n') {
                break;
            } else if (ch==0x1b) {
                seed = 100;
            }
        }
    } while (seed < 50);
}
