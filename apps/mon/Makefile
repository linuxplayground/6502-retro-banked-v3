TOP = .
ROM = ../../rom
LOADTRIM = python3 ../loadtrim.py
BUILD_DIR = build

.PHONY: clean all

all: clean
	mkdir -pv $(BUILD_DIR)
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/mon.lst -o $(BUILD_DIR)/main.o main.s
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/getline.lst -o $(BUILD_DIR)/getline.o lib/getline.s
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/math.lst -o $(BUILD_DIR)/math.o lib/math.s
	ld65 -C mon.cfg -o $(BUILD_DIR)/mon.raw -m $(BUILD_DIR)/mon.map $(BUILD_DIR)/main.o $(BUILD_DIR)/math.o $(BUILD_DIR)/getline.o
	$(LOADTRIM) $(BUILD_DIR)/mon.raw $(BUILD_DIR)/mon.bin
clean:
	rm -fr $(BUILD_DIR)
