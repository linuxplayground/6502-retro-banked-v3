TOP = .
ROM = ../../rom
LOADTRIM = python3 ../loadtrim.py
BUILD_DIR = build

.PHONY: clean all

all: clean
	mkdir -pv $(BUILD_DIR)
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/echo.lst -o $(BUILD_DIR)/main.o main.s
	ld65 -C echo.cfg -o $(BUILD_DIR)/echo.raw -m $(BUILD_DIR)/echo.map $(BUILD_DIR)/main.o
	$(LOADTRIM) $(BUILD_DIR)/echo.raw $(BUILD_DIR)/echo.bin
clean:
	rm -fr $(BUILD_DIR)
