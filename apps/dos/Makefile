TOP = .
ROM = ../../rom
LOADTRIM = python3 ../loadtrim.py
BUILD_DIR = build

.PHONY: clean all

all: clean
	mkdir -pv $(BUILD_DIR)
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/dos.lst -o $(BUILD_DIR)/main.o main.s
	ld65 -C dos.cfg -o $(BUILD_DIR)/dos.raw -m $(BUILD_DIR)/dos.map $(BUILD_DIR)/main.o \
	`../../rom/findsymbols ../../rom/build/monitor.sym ram_bank rom_bank fat32_ptr fat32_ptr2 fat32_bufptr fat32_lfn_bufptr` \
	`../../rom/findsymbols ../../rom/build/monitor.sym fat32_dirent prbyte`
	$(LOADTRIM) $(BUILD_DIR)/dos.raw $(BUILD_DIR)/dos.bin
clean:
	rm -fr $(BUILD_DIR)
