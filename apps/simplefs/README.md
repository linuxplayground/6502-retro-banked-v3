# Simple File System

A Homebrew filesystem for SD Cards that aims to strip away as much of the
complexity as possible.  Even a simple filesystem (by today's standards) such
as FAT32, can be quite complex.  There are clusters and chains of file
allocation tables to navigate and keep track of.  If this is your bag, then I
recommend the Commander X16 project on GitHub for a really good example of a
fully featured FAT32 Filesystem implementation.  For something a bit more
rudimentary and with a detailed description of how to interface with an SD
Card, checkout George Foot's examples.

This filesystem is intended to be used on a 6502 system with access to an
SD CARD.  Typically one driven by a VIA 65C22.  It's sole purpose is to allow
you the hobbiest to load and save programs to and from disk in much the same
way as we did back in the 80s.  A great many elegancies of modern filesystems
have been removed so that what's left is what I consider to be the bare minimum
for a working and debuggable files system.

- https://github.com/X16Community/x16-rom/tree/master/fat32
- https://github.com/gfoot/sdcard6502

Good luck!

## Features of the Simple File System

These are the features of the filesystem at the highest level.

- Preallocated files and data storage.  Each file can be a maximum of 64KB
  which is going to be sufficient for most (not all) usecases.
- Maximum of 2048 files
- Simple API

## Missing Features

- No support for partitions
- No ability to read the filesystem on a modern computer
- No random access support

## API

### Introduction

Every command will return with success or failure indicated by the carry flag.
C=0 means an error occurred and the error can be found in the global variable
`sfs_errno`.  C=1 means the command was successfull.

The basic flow to read a file into memory for example is:

- `sdcard_init` => init the sdcard
- `sfs_mount` => Load the VolumeID sector into memory, perform a sanity check
  and store the VolumeID into memory for use by the filesystem.
- store the address of the filename you want to read into the `sfs_fn_ptr`
  zeropage pointer.
- `sfs_find` => If C=1 then a file was found and the directory index loaded
  into memory.
- store the target address in memory where you want the file loaded to into the
  `sfs_data_ptr` zeropage pointer.
- `sfs_read` => Read the file into memory starting at the target address.

The filesystem has no way to close open files.

### Commands

**sfs_format**

INPUTS: NONE

The format command will write a new VolumeID block to the first sector of the
SD Card. The block data should be provided as per the details in the Physical
Layout section towards the end of this document.  It will also allocate the
`start` and `index_lba` fields for every directory index sector.

**sfs_mount**

INPUTS: NONE

The mount command loads the Volume ID into memory and prepares the filesystem
for subsequent commands.

**sfs_open_first_index_block**

INPUTS: NONE

All the files are enumerated in sectors `00000080 - 000000FF` on the SD Card.
This command loads sector `00000080` into the sector buffer and moves the
buffer pointer to the front of the buffer.

**sfs_read_index**

Use this command to enumarate through the files on the disk.  Each time you
call the command, it will return the next index unless it finds an index that
has a filename beginning with a null char.  (0x00).  This is how the filesystem
knows it has reached the end of used directory indexes.

The data will be stored in the global `index` variable.

_Note: Reading an index is the same as opening that index.  Subsequent calls to
sfs_read or sfs_write will operate on that file._

**sfs_create**

INPUTS: `sfs_fn_ptr` is assigned to the address of a zero terminated string for
the filename to create.  Filenames are not case sensitive and are limited to 21
chars.

The command will search for an existing file of the same name and will "open"
that file if it exists.  If the file is not found, then the command will search
for a new directory index or a directory index that has been previously marked
as deleted and return that instead.

_Note: The index is not saved to disk until `sfs_write`._

**sfs_write**

INPUTS: 

- An already open file given by `sfs_find` or `sfs_read_index` or `sfs_create`
- `sfs_bytes_rem` 16 Bit length of file to write in bytes.
- `sfs_data_ptr` address of start of data to copy to the file.

This command copies `sfs_bytes_rem` bytes of data from the location starting
at `sfs_data_ptr` into the opened file.  There are no file headers or other
metadata.  Just the raw data is copied in binary format.

**sfs_read**

INPUTS:

- An already open file given by `sfs_find` or `sfs_read_index`
- `sfs_data_ptr` address of start of target memory to read the contents of the
  file int.

This command will copy all the bytes of data defined by the `size` attribute of
the file's directory index into memory starting at `sfs_data_ptr`.

**sfs_delete**

INPUTS:

- An already open file given by `sfs_find` or `sfs_read_index`

Deletes the file by setting the directory index `attribute` value to 0xFF.

The data is not actaully removed from the disk and the directory index is not
altered in any other way.  Subsequent searches for a free index are free to use
this file at which time, data could be overwritten.

## Physical Disk Layout

The Simple Filesystem is designed for use with SD Cards.  SD Cards have a
default sector size of 512 bytes.  The sectors are used for three different
purposes:


- LBA=00000000 : VolumeID => Details of the filesystem, and some simple
  metadata.
- LBA=00000080 -> 000000FF : Directory Indexes => Details of the files stored
  on the disk.
- LBA=00000100 -> 00004180: Data => preallocated data clusters each 0x80
  sectors long which allows for 64KB of storage per file.

### The Volume ID

The Volume ID contains information about the disk.  It has the following
fields:

```
.struct sVolId
        id             .res 8   ; 8  0
        version        .res 4   ; 4  7
        index_start    .dword   ; 4 11
        index_last     .dword   ; 4 15
        data_start     .dword   ; 4 19
.endstruct
```

Here is the volume ID defined in CA65 Assembly:

```
VolumeID:       .byte "SFS.DISK"         ; 8 bytes volume ID
                .byte "0001"             ; 4 bytes VERSION
                .byte $80, $00, $00, $00 ; 4 bytes INDEX LBA
                .byte $80, $00, $00, $00 ; 4 bytes LAST INDEX LBA
                .byte $00, $01, $00, $00 ; 4 BYTES DATA START LBA
```

- id: ASCII Text.
- version: currently the filesystem version is defined as `0001` in ASCII.
- `index_start`: 32 bit address of the starting sector of the directory index
  sectors.
- `index_last`: 32 bit address of the last currently used sector of the
  directory index sectors.
- `data_start`: the first sector in which data is stored.  Note that the format
  function pre-allocates all the data start locations in the index table.

### Index Structure

The index structure defines details of a file.  Note that the format command
will pre-define both the `start` and `index_lba` values for each possible index
in the filesystem.

```
.struct sIndex
        filename       .res 21  ; 21  0
        attrib         .byte    ; 1  21
        start          .dword   ; 4  22
        index_lba      .dword   ; 4  26
        size           .word    ; 2  30
.endstruct
```

- `filename`: ASCII text, max 21 chars and must be right padded with spaces
  (0x20)
- `attrib`: 0x40 file in use, 0xFF file is deleted.
- `start`: 32 bit sector address of start of data.  Predefined by format.
- `index_lba`: 32 bit sector address of the SD Card block containing this
  particular index.
- `size`: 16Bit size of file in bytes.

**Notes on index management**

Key to keeping the fileysystem simple is the preallocation of index lba and
data start addresses by the format function.  This seriously reduces the
overhead of the filesystem.

New indexes will not be allocated past 0x000000FF sector on the SD Card.

