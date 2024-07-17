# ROM

I have leaned hevily on the commander x16 project for this work.  Rather than use Commodore Basic, I have
gone with ehBasic.  ehBasic has quite an extensive zeropage usage.  See the linker scripts in the 
`rom/cfg` folder for details.

## JSRFAR and RSTFAR

I have not been able to successfully use JSRFAR to reset the CPU into a specific ROM.  My workaround is the
`rstfar` function defined in `rom/kern/memory.s`.

## FAT32

Again, the FAT32 library written by *by Frank van den Hoef, Michael Steil* and hosted on the Commander X16
Community GitHub has been my soure of greatest learning and understanding.

A long time goal of mine has been to use rom banks effectively to make my homebrew 6502 projects more
useful.  The first step towards this goal was to figure out the needed hardware to burst through the 64KB
memory limit imposed by the 16bit wide address bus on the CPU. - See the [HARDWARE.md](./HARDWARE.md) file in this repo.

The next challenge, of course is to use the extra space wisely.  My memory map and hardware implimentation allows for 4 x 16KB banks of ROM Which are currently used as follows:

* BANK 0 - Kernel routines and drivers, Wozmon, Xmodem. - Default Bank.
* BANK 1 - ehBasic
* BANK 2 - FAT32 Library and SDCARD via SPI driver.
* BANK 3 - RESERVED

Once I had the banks figured out, I needed to learn how to call routines between banks.  The solution is a
short bit of kernel memory code that is copied over to the static ram at address 0x0200 on system reset.
This `jsrfar` routine uses the return pointer on the stack to figure out where the caller wants to go to
and which bank to switch to.  It also saves the current bank and restores that before returning to the 
caller.

One critical thing to note about jsrfar.  The zeropage variable imparm variable must be consistent.  You
can not repurpose that variable ever.  If you do, the jsrfar routine starts getting into trouble.

## Passing Symbols Between Banks

Another complex challenge which the X16 folks have figure out is how to pass symbols between banks when compiling them.  For this they use a bash script.  The `findsymbols` script will find and return ca65 `-D` commandline arguments for each symbol requested out of a map file.

For example:

In this repo, the monitor bank (bank 0) is also going to be responsible for the filesystem routines.
The various fat32 zeropage addresses and BSS data labels are all declared in the monitor bank.

When the Makefile gets around to complining and linking the FAT32 bank, it will need the addresses of these
symbols in order to reference them.  They can not be imported because they are not being linked against by
the linker in the traditional compile and link way.  Instead they are declared as symbols on the 
commandline to the linker.

Another way to do this can be seen in the kern.inc and fat32.inc includes in the `inc` directory.
In this case, the banks are building a jump table which the include refers to.  The addresses in the include file are the addresses of each jump instruction in the jumptable.

This works for labels to routines and allows us to maintain a standardised set of kernal calls.
All that's required for these is to make sure the kern.inc file is included and then execute `jsrfar`
calls to the kernel routines as required.

This approach doesn't really work for variable storage in the same way.  Of course it could, but then each
time the code changes, we would need to figure out the new locations of the variables and update the
include file.  That's not very developer friendly.
