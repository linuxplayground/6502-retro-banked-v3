# Simple File System

* Block 0 contains the volume ID
* Block 100 to 1FF contain the index
* Block 200 to END OF DISK contains the data.

* Each directory index is 32bytes consisting of the following fields
    * 00-21 22B FILENAME (SPACES FILLED TO RIGHT) UPPERCASE ONLY
    * 22-22 01B ATTRIB
    * 23-26 04B START SECTOR LBA ADDRESS
    * 27-30 04B END SECTOR LBA ADDRESS
    * 30-31 02B FILE SIZE IN BYTES

* The files are allocated to 64kb (128 sectors) each. The start and end sectors are used
    to identify the file extents and the size is for fine grained data.

* The ATTRIBUTE field contains information about the file.

There are no subdirectories.  JUST FILES.

AN INDEX IS FREE WHEN
        The filename begins with 0x00
