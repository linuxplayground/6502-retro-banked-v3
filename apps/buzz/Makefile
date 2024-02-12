TOP = .
ROM = ../../rom
LOADTRIM = python3 ../loadtrim.py
BUILD_DIR = build

.PHONY: clean all

all: clean
	mkdir -pv $(BUILD_DIR)
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/buzz.lst -o $(BUILD_DIR)/main.o main.s
	ld65 -C buzz.cfg -o $(BUILD_DIR)/buzz.raw -m $(BUILD_DIR)/buzz.map $(BUILD_DIR)/main.o
	$(LOADTRIM) $(BUILD_DIR)/buzz.raw $(BUILD_DIR)/buzz.bin
clean:
	rm -fr $(BUILD_DIR)/*
