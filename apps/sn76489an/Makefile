TOP = .
ROM = ../../rom
LOADTRIM = python3 ../loadtrim.py
BUILD_DIR = build

.PHONY: clean all

all: clean vgm
	mkdir -pv $(BUILD_DIR)
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/sn76489.lst -o $(BUILD_DIR)/main.o main.s
	ld65 -C sn76489an.cfg -o $(BUILD_DIR)/sn76489an.raw -m $(BUILD_DIR)/sn76489an.map $(BUILD_DIR)/main.o
	$(LOADTRIM) $(BUILD_DIR)/sn76489an.raw $(BUILD_DIR)/sn76489an.bin

vgm: 
	mkdir -pv $(BUILD_DIR)
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/vgm.lst -o $(BUILD_DIR)/vgm.o vgm.s
	ld65 -C sn76489an.cfg -o $(BUILD_DIR)/vgm.raw -m $(BUILD_DIR)/vgm.map $(BUILD_DIR)/vgm.o
	$(LOADTRIM) $(BUILD_DIR)/vgm.raw $(BUILD_DIR)/vgm.bin

piano:
	mkdir -pv $(BUILD_DIR)
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/piano.lst -o $(BUILD_DIR)/piano.o piano.s
	ld65 -C sn76489an.cfg -o $(BUILD_DIR)/piano.raw -m $(BUILD_DIR)/piano.map $(BUILD_DIR)/piano.o
	$(LOADTRIM) $(BUILD_DIR)/piano.raw $(BUILD_DIR)/piano.bin

clean:
	rm -fr $(BUILD_DIR)/*
