TOP = .
ROM = ../../rom
LOADTRIM = python3 ../loadtrim.py
BUILD_DIR = build

.PHONY: clean all

all: clean 
	mkdir -pv $(BUILD_DIR)
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/f18a.lst -o $(BUILD_DIR)/main.o main.s
	ld65 -C f18a.cfg -o $(BUILD_DIR)/f18a.raw -m $(BUILD_DIR)/f18a.map $(BUILD_DIR)/main.o
	$(LOADTRIM) $(BUILD_DIR)/f18a.raw $(BUILD_DIR)/f18a.bin

clean:
	rm -fr $(BUILD_DIR)/*
