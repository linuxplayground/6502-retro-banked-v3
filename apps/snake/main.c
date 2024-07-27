#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "6502-retro.h"
#include "font40.h"

#define head_up    0x01
#define head_dn    0x02
#define head_lt    0x03
#define head_rt    0x04
#define applechar  0x05

#define BUFFER_SIZE 0x1000

uint16_t addr = 0;

uint16_t seed = 0;
uint8_t grow = 2;
uint16_t score = 0;
uint8_t ticks = 0;
uint8_t game_speed = 12;
bool crashed = false;

uint8_t buffer[BUFFER_SIZE] = {0};
uint16_t buffer_head = 0;
uint16_t buffer_tail = 0;

uint8_t x, y, c, r, i, j = 0;

struct {
    int8_t x;
    int8_t y;
    uint8_t dir;
} head;

struct {
    uint8_t x;
    uint8_t y;
} apple;

char tb[40];


char read_char_at_xy(uint8_t x, uint8_t y) {
        return screenbuf[y*32+x];
}

void print_at_xy(uint8_t x, uint8_t y, char * text) {
        uint8_t *sb = screenbuf + (y*32) + x;
        do {
                *sb= *text;
                ++sb;
                ++text;
        } while (*text != 0);
}

void char_at_xy(uint8_t x, uint8_t y, char c) {
        screenbuf[(y*32)+x] = c;
}

void set_pattern_color(uint8_t pattern, uint8_t color) {
        vdp_write_address(pattern * 8 + VDP.colortable);
        for (i=0; i<8; ++i) {
                VDP_DAT = color;
        }
}

void print_center_y(uint8_t y, char * s) {
        uint8_t len = strlen(s);
        uint8_t x = 15-(len/2);
        print_at_xy(x,y,s);
}

void new_apple() {
        bool taken = true;
        while(taken) {
                x = (rand() % 32);
                y = (rand() % 24);
                if (read_char_at_xy(x,y) == 0x20) {
                        taken = false;
                        apple.x = x;
                        apple.y = y;
                }
        }
        char_at_xy(apple.x, apple.y, applechar);
        grow = 2;
}

uint8_t menu(void) {
        print_center_y(3, "SNAKE 6502 - V1.0");
        print_center_y(5, "BY PRODUCTION-DAVE");
        print_center_y(13,"PRESS [SPACE] TO PLAY");

        sprintf(tb, "SCORE: %d", score);
        print_center_y(7, tb);

        if (crashed == true) {
                print_center_y(23, "CRASHED");
        }

        vdp_wait();
        vdp_flush();

        seed = 0;
        while (1) {
                c = acia_getc_nw();
                ++seed;
                if (c == 0x1b) {
                        return 0;
                } else if (c == 0x20) {
                        return 1;
                }
        }
}

void new_game(void) {

        vdp_clear_screen();
        memset(screenbuf, 0x20, 0x300);
        buffer_head = 0;
        buffer_tail = 0;
        head.x = 15;
        head.y = 20;
        head.dir = head_rt;
        game_speed = 8;
        ticks = 0;
        crashed = false;
        grow = 2;
        score = 0;
        new_apple();
        vdp_wait();
        vdp_flush();
}

void run(void) {
        do {
                if (ticks == game_speed) {
                        c = acia_getc_nw();

                        if (c == 0x1b) {
                                crashed = true;
                                acia_puts("ESCAPE PRESSED - ");
                        } else if (c == 0x61) {
                                if (head.dir != head_rt) head.dir = head_lt;
                        } else if (c == 0x64) {
                                if (head.dir != head_lt) head.dir = head_rt;
                        } else if (c == 0x77) {
                                if (head.dir != head_dn) head.dir = head_up;
                        } else if (c == 0x73) {
                                if (head.dir != head_up) head.dir = head_dn;
                        }

                        if (head.dir == head_lt) {
                                head.x--;
                        } else if (head.dir == head_rt) {
                                head.x++;
                        } else if (head.dir == head_up) {
                                head.y--;
                        } else if (head.dir == head_dn) {
                                head.y++;
                        } else {
                                crashed = false;
                        }

                        if ( head.x < 0 || head.x > 31 ) {
                                crashed = true;
                                acia_puts("HIT BOUNDARY - ");
                        }
                        if ( head.y < 0 || head.y > 23 ) {
                                crashed = true;
                                acia_puts("HIT BOUNDARY - ");
                        }

                        r = read_char_at_xy(head.x, head.y);
                        if (r == applechar) {
                                sn_beep();
                                score += 5;
                                if (score % 25 == 0) {
                                        if (game_speed > 0) game_speed -= 1;
                                }
                                new_apple();
                        } else if (r != 0x20) {
                                crashed = true;
                                acia_puts("HIT TAIL - ");
                        }
                        if (crashed == false) {
                                char_at_xy(head.x, head.y, head.dir);
                                if (buffer_head > BUFFER_SIZE) {
                                        buffer_head = 0;
                                }
                                buffer[buffer_head] = head.x;
                                buffer[buffer_head+1] = head.y;
                                buffer_head += 2;

                                if (grow > 0) {
                                        grow --;
                                } else {
                                        char_at_xy(buffer[buffer_tail], buffer[buffer_tail+1], 0x20);
                                        buffer_tail += 2;
                                        if (buffer_tail > BUFFER_SIZE) {
                                                buffer_tail = 0;
                                        }
                                }
                                vdp_wait();
                                vdp_flush();
                                ticks = 0;
                        }
                } else {
                        vdp_wait();
                        ticks ++;
                }

        } while (crashed == false);
        sn_beep();
        sprintf(tb, "%d\n", score);
        acia_puts(tb);
}
int main() {
    vdp_init_g2mode();
    vdp_load_font_wrapper(font40, 0x0400);

    memset(screenbuf, 0x20, 0x300);

    vdp_write_address(VDP.colortable);
    for (addr=0; addr<0x1800; ++addr) {
        VDP_DAT = 0xe1;
    }

    //Set snake character colours
    set_pattern_color(head_up, 0x61);
    set_pattern_color(head_dn, 0x61);
    set_pattern_color(head_lt, 0x61);
    set_pattern_color(head_rt, 0x61);
    set_pattern_color(applechar,   0x21);

    sprintf(tb, "Free memory: %d\n", _heapmemavail());
    acia_puts(tb);
    while(1) {
            if( !menu() ) {
                    break;
            } else {
                    new_game();
                    run();
            }
    }
    return 0;
}
