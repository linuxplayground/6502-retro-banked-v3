# 6502 Development Environment

I write all my 6502 assembly with the CA65 Assembler.

The linker file for the banked memory breadboard computer looks like this:

```text
TODO: Update Linker File
```

## Composing the ROM

The ROM IC I am using is an SST27SF512 FLASH ROM.  It has 64KB of storage which
can be divided into 4 x 16KB ROM Images.  These are compiled indpendantly and
joined up into a single image prior to flashing.

At this time, I only have one image for testing.  I will be working on adding
ehBASIC, and Forth into the additional banks.  I shall also look at delivering
the FAT 32 library into one of the ROM BANKs.  More on this as I get there.
