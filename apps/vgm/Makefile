TOP = ..

ROM =$(TOP)/../rom
LIB=$(TOP)/lib
LOADTRIM = python3 $(TOP)/loadtrim.py

BUILD_DIR = build
BIN=vgm

CAFLAGS=--cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/$(BIN).lst -o $(BUILD_DIR)/main.o
LDFLAGS=-C $(LIB)/6502-retro.cfg -o $(BUILD_DIR)/$(BIN).raw -m $(BUILD_DIR)/$(BIN).map $(BUILD_DIR)/main.o

.PHONY: clean all

all: clean vgm

vgm:
	mkdir -pv $(BUILD_DIR)
	ca65 $(CAFLAGS) main.s
	ld65 $(LDFLAGS)
	$(LOADTRIM) $(BUILD_DIR)/$(BIN).raw $(BUILD_DIR)/$(BIN).bin

clean:
	rm -fr $(BUILD_DIR)/*
