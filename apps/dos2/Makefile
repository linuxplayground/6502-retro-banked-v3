TOP = .
ROM = ../../rom
LOADTRIM = python3 loadtrim.py
BUILD_DIR = build

LIB_SOURCES = 
LIB_OBJS = $(addprefix $(BUILD_DIR)/, $(LIB_SOURCES:.s=.o))

RAW = $(BUILD_DIR)/dos.raw
BIN = $(BUILD_DIR)/dos.bin

.PHONY: clean all

all: clean $(BIN)

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/$*.lst $< -o $@

$(BUILD_DIR):
	mkdir -pv $@

$(RAW): main.s $(BUILD_DIR) $(LIB_OBJS)
	ca65 --cpu 65c02 -I $(ROM)/inc -l $(BUILD_DIR)/$*.lst $< -o $(BUILD_DIR)/main.o
	ld65 -C dos.cfg -m $(BUILD_DIR)/dos.map $(BUILD_DIR)/main.o $(LIB_OBJS) -o $@ \
	`$(ROM)/findsymbols $(ROM)/build/monitor.sym fat32_ptr fat32_dirent fat32_size fat32_dirent fat32_errno` \
	`$(ROM)/findsymbols $(ROM)/build/monitor.sym ram_bank rom_bank`

$(BIN): $(RAW)
	$(LOADTRIM) $< $@

clean:
	rm -fr $(BUILD_DIR)
