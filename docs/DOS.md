# DOS and the Simple File System (SFS)

The 6502-Retro! has a custom filesystem called SFS or Simple File System.  The
filesystem has some basic features that make it easy to debug problems but have
the potentially negative side effect of not being compatible with any other
filesystem one might find on a modern computer.  This means that that the SDCARD
will not mount on any other computer besides the 6502-Retro!

## Features

- Preallocated files and data storage.  Each file can be a maximum of 64KB
  which is going to be sufficient for most (not all) usecases.
- Maximum of 2048 files

There is no support for partitions, directories or random access.

## DOS

The DOS utility on ROM BANK 0 allows the user to perform a file listing, load
files from SDCARD to memory, save data from memory into a file, type the
contents of text files to the terminal and format the filesystem.

### Format

After running the format command (f and confirming with a captital Y) the SDCARD
will have all of it's 2048 file indexes deleted.  A `dir` at this point will
show an empty DISK.

### Saving memory into a file

```
save filename start(16) size(16)
```

- Filename: String (no quotes) 21chars
- Start: address of start of data to save given as 16bit HEX value with leading
  zeros provided.
- Size: number of bytes to save given as 16bit HEX value with leading zeros
  provided.

The process for storing data on the SDCARD requires the data to first exist in
RAM.  There are two types of storage options.

- Store from LOW RAM
- Store from EXTENDED RAM

The save command takes 3 arguments:  Filename, Starting location in RAM, size of
file to save in BYTES given as hexadecimal.

```text
save hello.bin 0800 0042
```

Save 0x0042 bytes of data starting at 0x0800 into a file called "hello.bin"

If you specify the starting location as 0xA000 (the start of extended memory)
the save function will support saving data up to 64KB.  It will begin at RAM
BANK 1 and continue until all bytes by the given size argument are saved.

NOTE: The Save utility does not have any controls in place for preventing
overflow into IO memory or dealing with high ram memory.  You are likely to
crash DOS if you try to save a file from low ram and provide a size in bytes
that crosses the 0x9EFF upper limit.  For large files, it's best to load them
into Extended memory using the XMODEM utility (capital X on the start menu) and
then saving the file to SDCARD starting at address 0xA000.

### Loading a file from SDCARD into RAM

```text
load filename start(16)
```

- Filename: String (no quotes) 21chars max.  Wildcards are supported for the end
  of the string only.  EG: `load hello* 0800` will find the first file that has
  a name beginning with "hello"
- Start: The starting address to save data into ram given as 16bit HEX with
  leading zeros provided.

The process to load a file from SDCARD into RAM requires the filename to be
provided and the start address to save the file into.

```text
load hello.bin 0800
```

This will load the file called hello.bin into memory starting at 0x0800.  The
the load routine does not have any protection for crossing the memory mapped IO
at 0x9F00.  If you have large files to load, it's best to load them into
extended memory by providing the starting address as 0xA000.

When the starting address is 0xA000, the load routine in SFS will fill up blocks
of extended memory as required.

## Run

The run command is much the same as the run command on the start menu.  The
program must first be loaded into memory with the load command and then the run
command can be used to execute it.

The run command prompts for an address to run from.  If none is provided by
simply pressing enter without giving an address, the Run command will default to
executing code at 0x800.
