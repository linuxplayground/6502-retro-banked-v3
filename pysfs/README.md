# PySFS

A Python library for working with SFS images on a modern computer.

A standard SFS image will be 128.5 MB which is enough to hold 2048 64 KB files and all of the indexes for them.

These commands are inspired the CPM-TOOLS.


## API

### sfs.__init(<filename>)

Mounts the filesystem passed in.

### sfs.format()

Creates and writes superblock.  Clears and inits indexes.

### sfs.find(<filename>)

Searches for filename.  Returns False if not found.

### sfs.find_free_index()

Searches for unused index.  Returns False if none found.

### sfs.write(<data>)
Updates current index (from find or find_free) with length of data.  Then saves index to disk. Updates superblock.last_index if neccessary and saves superblock to disk. Writes data to disk at index.start

### sfs.read()

Returns the current index.size length of binary data read from the disk at start location given by current index.

### sfs.dir()

Prints out the size and filename of every used index up to superblock.last_index

## The CLI

The CLI has the following commands:

```bash
./cli.py --help
Usage: cli.py [OPTIONS] COMMAND [ARGS]...

  A CLI tool to manage SFS File images.  These images can be raw copied over
  to an SDCARD for use on the 6502-Retro V3 Breadboard computer.

  Use: `./cli.py <CMD> --help` to learn more information about a specific
  command.

Options:
  --help  Show this message and exit.

Commands:
  cp      Copies a file from SOURCE to DESTINATION.
  delete  Deletes a file NAME from disk IMAGE.
  dir     Lists files on the SCARD Image.
  format  Formats a new image.
  new     Creates a new SFS Disk <IMAGE> and formats it.
```

### NEW

Creates a new SFS image file and formats it.  A 128.5 MB file will be created filled with NULL Bytes except for the VOLUME ID block.

```bash
./cli.py new --help
Usage: cli.py new [OPTIONS]

  Creates a new SFS Disk <IMAGE> and formats it.

  The volume name is "SFS.DISK"

Options:
  -i, --image TEXT  Path to local SDCARD image.  [required]
  --help            Show this message and exit.
```

### FORMAT

Similar to the NEW command except, an existing image file is required.

```bash
./cli.py format --help
Usage: cli.py format [OPTIONS]

  Formats a new image. First create image with `dd if=/dev/zero of=sdcard.img
  count=40100 bs=512`

Options:
  -i, --image TEXT  Path to local SDCARD image.  [required]
  --help            Show this message and exit.

```

### DIR

Lists all the files on the SFS image.


```bash
./cli.py dir --help
Usage: cli.py dir [OPTIONS]

  Lists files on the SCARD Image.

Options:
  -i, --image TEXT  Path to local SDCARD image.  [required]
  --help            Show this message and exit.
```

### COPY

Use this command to copy files to and from your local filesystem into the SFS Image file.

```bash
./cli.py cp --help
Usage: cli.py cp [OPTIONS]

  Copies a file from SOURCE to DESTINATION.

  PATHS on the SFS Volume must be prefixed with sfs:// LOCAL PATHS must be
  either full or relative paths.  Relies on python open() to access.

Options:
  -i, --image TEXT        Path to local SDCARD image.  [required]
  -s, --source TEXT       The source. Either sfs://<filename> or ./<filename>
                          [required]
  -d, --destination TEXT  The destination. Either sfs://<filename> or
                          ./<filename>  [required]
  --help                  Show this message and exit.
```

### DELETE

Delete a file from the SFS image.

```bash
./cli.py delete --help
Usage: cli.py delete [OPTIONS]

  Deletes a file NAME from disk IMAGE.

Options:
  -i, --image TEXT  Path to local SDCARD image.  [required]
  -n, --name TEXT   The file to delete.  sfs://<filename>  [required]
  --help            Show this message and exit.
```

