TOP = .
ROM = ../../rom
LOADTRIM = python3 ../loadtrim.py
BUILD_DIR = build

.PHONY: clean all

all: clean
	mkdir -pv $(BUILD_DIR)
	ca65 --cpu 65c02 -I $(ROM)/inc -g -l $(BUILD_DIR)/monitor.lst -o $(BUILD_DIR)/monitor.o main.s
	ld65 -C monitor.cfg -o $(BUILD_DIR)/monitor.raw -m $(BUILD_DIR)/monitor.map -Ln $(BUILD_DIR)/monitor.sym $(BUILD_DIR)/monitor.o
	python3 ./loadtrim.py $(BUILD_DIR)/monitor.raw $(BUILD_DIR)/monitor.bin
clean:
	rm -fr $(BUILD_DIR)
