# 6502 Development Environment

I write all my 6502 assembly with the CA65 Assembler.

The linker file for the banked memory breadboard computer looks like this:

```text
MEMORY {
        # RAM
        ZP:     start =    $0, size =  $100, type = rw, define = yes;
        SYSTEM: start =  $200, size =  $600, type = rw, define = yes, fill = yes, fillval = $00, file="";
        LORAM:  start =  $800, size = $9EFF, define = yes;
        # IO
        BANK:   start = $9F00, size = $000f, type = rw, define = yes;
        ACIA:   start = $9F10, size = $000F, type = rw, define = yes;
        VIA:    start = $9F20, size = $000F, type = rw, define = yes;
        # HIRAM
        HIRAM:  start = $A000, size = $2000, type = rw, define = yes;
        # ROM
        ROM:    start = $C000, size = $3E00, type = ro, fill=yes, fillval=$ea, file=%O;
        PAGEFE: start = $FE00, size = $0100, type = ro, fill=yes, fillval=$ea, file=%O;
        PAGEFF: start = $FF00, size = $0100, define=yes, fill=yes, fillval=$ea, file=%O;
}

SEGMENTS {
        ZEROPAGE: load = ZP,       type = zp,  define = yes;
        SYSRAM:   load = SYSTEM,   type = rw,  define = yes, align=$0100,    optional=yes;
        BSS:      load = SYSTEM,   type = rw,  define = yes, align=$0100,    optional=yes;
        CODE:     load = ROM,      type = ro;
        RODATA:   load = ROM,      type = ro;
        BANKHANDLER: load = PAGEFE, type= ro;
        SYSCALLS: load = PAGEFF    type = ro;
        VECTORS:  load = PAGEFF,   type = ro, offset = $00FA;
}
```

## Composing the ROM

The ROM IC I am using is an SST27SF512 FLASH ROM.  It has 64KB of storage which
can be divided into 4 x 16KB ROM Images.  These are compiled indpendantly and
joined up into a single image prior to flashing.

Currently the Makefile has a recipe called, `make world` which will build both the main rom
and ehBasic.  These are then combined into a single 32kb file which can be flashed to the ROM.

## Memory Bank Management

Once the hardware side of things was sorted and setup, I needed ot figure out how best
to deal with switching between banks of memory.  There are 2 main usecases for program flow and
one or two for data management that I will try to cover below.

* Program flow:
    * Switch to a new ROM and jump to the reset vector for that rom.  IE: Switching from the monitor
        to basic and back again.
    * Call a subroutine in a different bank.
* Data:
    * Save data into banked memory with automatic bank increments as each bank fills up.  I suspect
        that this is the sort of thing needed when loading data from a disk for example.
    * Copy data between banks.  I am not quite sure where this might be required yet.

All the routines for banking are in the `bank.s` file and placed by the linker at page $FE.
Each ROM includes the same PAGE so the bank routines are consistent across all banks.

The alternative to this approach is to have the main init routine in ROM Bank 0 which runs on first
boot, copy the bank routines into LOW RAM and call them from there.  For now, I have gone with using up
a page of ROM memory in each rom for this purpose.

### Program Flow: Switch to ROM and Reset

This is the simplest bank switch operation because it assumes that all state can be destroyed.  There
are no variables to hold on to and the stack can be reset.

```asm
; set the rom bank and reset
; resets ram bank too
; INPUT : A contains the rom bank number to switch to.
rstfar:
	sta	__BANK_START__ + 1
	sta	rom_bank
	stz	__BANK_START__ + 0
	sta	ram_bank
rom_reset:
	jmp ($FFFC)	     ; do a hard reset to whatever is defined in this rom.
```

### Subroutine Calls to a Different Bank

This was the hardest part for me to get my head around.  I have copied the code almost verbatim
from the CommanderX16 project.  [https://github.com/commanderx16/x16-rom/blob/master/inc/jsrfar.inc](https://github.com/commanderx16/x16-rom/blob/master/inc/jsrfar.inc)

I will try to explain how this `jsfar` function works.  It's quite heavy so if performance is important
then perhps consider colocating your functions in the same memory bank.

We have 3 main components:

- Caller: The code that's making the call.
- JSFAR: The call handler that's responsible for switching to the desired bank and switching back again.
- Callee: the function being called.

Consider the following caller assembly code from my ehBasic min_mon.asm.

```asm
ACIAin
      ; jmp _acia_getc_nw
      jsr   jsfar
      .word $FF06
      .byte $00
      rts
```

Here, the memory address $FF06 refers to a kernal jump vector hosted in ROM BANK 0.  In regular non-
banked uses, a caller would do something like, `jmp ($FF06)`

The structure of this call is a bit different.  We first have the regular call to `jsfar` and follow
that with a word of data containing the address of the function in the remote bank we want to execute
followed by a byte of data that indicates the bank.

With this approach, we are free to use A, X, Y and Status registers as normal.  They are preserved by
`jsfar` and made availale to the callee.

When the program counter arrives at the address of JSFAR in page FE, the following actions are taken.

1. reserve one byte of data on the stack to hold the current bank number later.
2. push the registers and the status to the stack.
3. use the stack pointer to read the return address (last byte of the JSR instruction that got us here)
    into a pointer as well as the target bank.
4. Add 3 to the pointer and save the pointer back to the stack so when we finally return from JSFAR,
    we return to the location immeidately after `.byte $00`.
5. Read the high byte of the function address provided and decide if the target function is in ROM or RAM.
6. Assume that we are always trying to hit a function in a RAM or ROM BANK different to our own.
7. store the current bank number into the reserved byte.
8. Write the target function address into LOW RAM into a special location that forms part of a
    JUMP INDIRECT instruction.  More on this in details below.
8. set the bank register to the desired bank.
9. restore the registers and processor status from the stack.
10. JSR to the address of the JUMP INDIRECT function in LOW RAM. -- Callee executes it's code and returns.
11. On return from callee, save registers so they can be used to reset the original BANK.
12. Restore all registers from the stack and return to caller.


I know this is complex.  The trickiest part for me, was that bit about writing to a JUMP instruction in
a special location in LOW RAM.

The way this works, is when the initial rom boots it writes the `C6` opcode to an address labled `jmpfr`
which is defined in `sysram.s`.  The following 2 bytes are also reserved.

```asm
jmpfr:                          .res 3
```
sysram.s

```asm
        lda     #$6c      ; save jmp opcode to jmpfr.
        sta     jmpfr
```
6502-rom.s

JSFAR then updates the two bytes following the `C6` when it fetched that data from the caller.

```asm
	ldy     #1
	lda     (imparm),y  ;target address lo
	sta     jmpfr+1     ; jmp LL HH (This is the LL part of self modifying code.)
	iny     
	lda     (imparm),y  ;target address hi
	sta     jmpfr+2     ; jmp LL HH (This is the HH part of the self modifying code.)
```
bank.s

JSFAR then performs a `JMP (jmpfr)`.

You can think of this as self modifying code.  We are not updating the actual opcode, but we are updating
its argument.

### GOTCHA

I hear you.  I have forced indirect jumps on you.  Well - most of the kernal functions that might be
called this way, will be included in the page FF vector table.  So i went with this option to keep things
as simple as possible.  The vector table API will be unlikely to change, while the actuall addresses of 
the functions referenced by the vector table will chage as I continue to work on them.

