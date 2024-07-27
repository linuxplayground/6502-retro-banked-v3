# 6502-Retro! Operating System

The 6502-Retro! Operating System is the interface you are presented with when
the system powers on.

```text
6502-Retro!!

USAGE INSTRUCTIONS
==============================================================================
h => help
b => ehBasic
d => DOS
p => Hopper
m => Wozmon
r => Run from 0x800
s => SMON
x => Xmodem receive
X => Xmodem receive into extended memory


>
```

The interaface is very simple.  Press the indicated key to luanch the function
you need.

## ehBasic

Switch to ROM BANK 1 and cold start ehBasic.  Note: Warm start has been disabled
altogether.

## DOS

Launch the DOS utiltiy to manage the SDCard.  You can load binary programs from
the SDCARD and execute them from inside DOS.

You can also save programs currently in memory to the SDCARD.

## Hopper

Switch to ROM BANK 2 and initialize the Hopper Minimal Run Environment.

## Wozmon

Runs the WOZMON application out of ROM.  Handy for inspecting memory.

## Run from 0x800

The RUN tool will prompt for a run start address in case your software is
compiled to run from an address other than 0x800.  The default, if you just
press enter, will be to performa  Jump Subroutine (JSR) to 0x800.  Applications
are expected to Return From Subroutine (RTS) when they exit.

## SMON

Switch to ROM BANK 3 and start smon6502.

## Xmodem Receive

This will load any file into memory at a location given by the first two bytes
of the file being loaded.

## Xmodem Receive into extended memory

This will load a large file into extended memory starting at BANK #1 - 0xA000.
As many banks as are required will be consumed to load the entire file.

Note: This version of XMODEM does not expect the first 2 bytes to contain a load
address.
