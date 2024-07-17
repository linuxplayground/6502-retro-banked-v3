# 6502-Retro-Banked (Version 3)

This is version 3 of the 6502-Retro! design.

## Core System

- WD65C02 Processor
- 39.75 KB SRAM 0x0000-0x9EFF
- 256 Bytes IO 0x9F00-0x9FFF
- 64 x 8 KB Extended SRAM 0xA000-0xBFFF
- 4 x 16 KB ROM 0xC000-0xFFFF
- AT22V10C Programmable Logic Device for address decoding
- Power supply via USB-Mini connector
- DS1813 - Reset supervisor
- 4 MHz System Clock
- 1.8432 MHz Baud Rate Clock

## Peripherals

- WD65C22 Versatile Interface Adaptor (VIA)
- R6551 Rockwell UART Adapter
- SN76489 Programmable Sound Generator
    - Header connector for amplified speaker
- F18A Video Display Processor - FPGA Emulating TMS9918A

## ROM ALLOCATIONS

- Bank 0: 6502-Retro! OS
    - System menu
    - Wozmon
    - DOS
        Simple File System (SFS) a custom, minimal filesystem for use with the
        6502-Retro!
    - Xmodem
- Bank 2: ehBasic
    - ehBasic is extended to support the following extra commands:
        - dir - File listing
        - load - Load a BASIC file from the SDCARD in raw ASCII listing form.
        - save - Save a BASIC file to the SDCARD in raw ASCII listing form.
        - beep - Emit a short beep from the speaker.
- Bank 3: Hopper HS (https://github.com/sillycowvalley/Hopper)
- Bank 4: EMPTY

## Memory Banking Logic

Memory banks are controlled by 2 write only registers.  0x9F00 for Extended RAM
bank switching and 0x9F01 for ROM Bank switching.  On reset these two registers
are initialised to 0 which results in the main system being loaded on boot.
Two ZeroPage addresses are reserved for maintaining a copy of the current value
of the bank registers.

## Serial Interface

By default, the OS is configured to support an FTDI type serial adapter with the
following settings:

- 8 Data bits
- 1 Stop bit
- No parity bit
- 115200 Baud
- No Hardware flow control

## IO Address Map

|ADDRESS        |DEVICE
|---            |---
|0x9F00         |RAM Bank Register (WRITE ONLY)
|0x9F01         |ROM Bank Register (WRITE ONLY)
|0x9F10         |ACIA Data
|0x9F11         |ACIA Status
|0x9F12         |ACIA Command
|0x9F13         |ACIA Control
|               |
|9F20           |VIA Port B
|9F21           |VIA Port A
|9F22           |VIA Data Direction B
|9F23           |VIA Data Direction A
|9F24           |VIA Timer 1 Counter Low
|9F25           |VIA Timer 1 Counter High
|9F26           |VIA Timer 1 Latch Low
|9F27           |VIA Timer 1 Latch High
|9F28           |VIA Timer 2 Counter Low
|9F29           |VIA Timer 2 Counter High
|9F2A           |VIA Shift Register
|9F2B           |VIA Auxillary Control Register
|9F2C           |VIA Program Control Register
|9F2D           |VIA Interrupt Flags Register
|9F2E           |VIA Interrupt Enable Register
|9F2F           |VIA PORT A (No Handshake)
|               |
|0x9F30         |F18A RAM
|0x9F31         |F18A Register

