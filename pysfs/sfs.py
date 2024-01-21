from config import *
from superblock import Superblock
from index import Index


class SFS(object):

    def __init__(self, image_file, name="SFS.DISK"):
        self.fd = open(image_file, 'rb+')
        self.sb = Superblock(name)

        self.idx_first_flag = True
        self.idx_pos = 0        # First index
        self.idx_lba = INDEX_SECTOR_START
        self.idx = None

    def __del__(self):
        self.fd.close()

    def format(self):
        self.sb.save(self.fd)
        data_start = 0x100
        self.fd.seek(INDEX_SECTOR_START * SECTOR_SIZE)

        # clear out indexes first
        for i in range(INDEX_SECTOR_START, DATA_SECTOR_START):
            self.fd.write(bytearray(SECTOR_SIZE))

        for i in range(INDEX_SECTOR_START,DATA_SECTOR_START):
            for j in range(int(SECTOR_SIZE / INDEX_SIZE)):
                index_lba = bytearray(i.to_bytes(4, "little"))
                data  = bytearray(data_start.to_bytes(4,"little"))
                self.fd.seek( (i*SECTOR_SIZE) + (j*INDEX_SIZE) + 22)
                self.fd.write(data)
                self.fd.write(index_lba)
                data_start += DATA_SECTOR_COUNT
        self.fd.flush() 
    
    def read_index(self):
        if self.idx_first_flag == True:
            self.idx_first_flag = False
            self.idx_lba = INDEX_SECTOR_START
            self.idx_pos = 0
        else:
            self.idx_pos += 0x20
            if self.idx_pos >= 0x200:
                self.idx_pos = 0
                self.idx_lba += 1
                if self.idx_lba > self.sb.index_last:
                    return False
        self.fd.seek(self.idx_lba * SECTOR_SIZE)
        block = self.fd.read(SECTOR_SIZE)
        idx = Index(block[self.idx_pos:self.idx_pos+INDEX_SIZE])
        return idx

    def find_free_index(self):
        self.idx_first_flag = True
        while 1:
            idx = self.read_index()
            if idx:
                if idx.attrib in [0x00, 0xFF]:
                    self.idx = idx
                    return True
            else:
                return False

    def find(self, filename):
        self.idx_first_flag = True
        while 1:
            idx = self.read_index()
            if idx != False:
                if filename  == idx.filename.decode():
                    self.idx = idx
                    self.idx.filename = filename        # READING THE FILENAME BACK SEEMS TO NOT WORK
                    return True
            else:
                return False
    
    def create(self, filename):
        if self.find(filename):
            self.idx.filename = filename
            self.idx.attrib = 0x40
            return True
        elif self.find_free_index():
            self.idx.filename = filename
            self.idx.attrib = 0x40
            return True
        else:
            return False

    def write(self, data):
        if len(data) > 65535:
            print(f'Data length to write is {len(data)} bytes...')
            return False        # File is too big
        self.idx.size = len(data)
        self.idx.flush(self.fd, self.idx_pos)
        if self.idx.index_lba > self.sb.index_last:
            self.sb.index_last = self.idx.index_lba
            self.sb.save(self.fd)

        self.fd.seek(self.idx.start * SECTOR_SIZE)
        self.fd.write(data)
        return True

    def read(self):
        self.fd.seek(self.idx.start * SECTOR_SIZE)
        return self.fd.read(self.idx.size)
    
    def dir(self):
        print(f'DIR: {self.sb.id}\n')
        print(' SIZE  NAME\n')
        self.idx_first_flag = True
        while(1):
            idx = self.read_index()

            if idx == False:
                break
            if idx.attrib in [0x00, 0xFF]:
                continue
            else:
                print(f'{str(idx.size).rjust(5, " ")}  {idx.filename.decode("ascii")}')
    
    def unlink(self):
        self.idx.attrib = 0xFF
        self.idx.flush(self.fd, self.idx_pos)
