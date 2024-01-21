from config import *

class Index(object):
    """
    .struct sIndex
        filename       .res 21  ; 21  0
        attrib         .byte    ; 1  21
        start          .dword   ; 4  22
        index_lba      .dword   ; 4  26
        size           .word    ; 2  30
    .endstruct
    """
    def __init__(self, barray):
        self.filename  = barray[0:21].strip()
        self.attrib    = barray[21]
        self.start     = int.from_bytes(barray[22:26], byteorder="little")
        self.index_lba = int.from_bytes(barray[26:30], byteorder="little")
        self.size      = int.from_bytes(barray[30:32], byteorder="little")

    @staticmethod
    def name2filename(filename):
        # name_len = len(filename)
        name_bytes = f'{filename[:21]}'.ljust(21, ' ')
        return name_bytes
    
    def index2ba(self):
        return b"".join([
            bytearray(Index.name2filename(self.filename),encoding="ascii"),
            bytearray(self.attrib.to_bytes(1,"little")),
            bytearray(self.start.to_bytes(4,"little")),
            bytearray(self.index_lba.to_bytes(4,"little")),
            bytearray(self.size.to_bytes(2, "little"))
        ])
    
    def flush(self, fd, idx_pos):
        fd.seek(self.index_lba * SECTOR_SIZE + idx_pos)
        fd.write(self.index2ba())
