.PHONY: all clean
CC=cl65
AS=ca65

LIB=../lib
LOADTRIM = python3 ../loadtrim.py
BUILD_DIR = build
BIN=vdp_c
CCFLAGS=-t none -Ln $(BUILD_DIR)/$(BIN).sym -C $(LIB)/6502-retro.cfg -m $(BUILD_DIR)/$(BIN).map -o $(BUILD_DIR)/$(BIN).raw -I $(LIB) -l $(BUILD_DIR)/$(BIN).lst -O

all: clean bin

bin:
	mkdir -pv $(BUILD_DIR)
	$(CC) $(CCFLAGS) main.c $(LIB)/exports.o $(LIB)/vdp_wrappers.o
	$(LOADTRIM) $(BUILD_DIR)/$(BIN).raw $(BUILD_DIR)/$(BIN).bin

clean:
	rm -fr $(BUILD_DIR)
	rm -f *.o
