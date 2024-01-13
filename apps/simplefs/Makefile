TOP = ../..
CC           = cc65
AS           = ca65
LD           = ld65

# global includes
ASFLAGS     += -I $(TOP)/rom/inc
# for sfs
ASFLAGS     += -D CPU_65C02=1
# put all symbols into .sym files
ASFLAGS     += -g
# Allow labels without colons
ASFLAGS     += --feature labels_without_colons
# all files are allowed to use 65SC02 features
ASFLAGS     += --cpu 65SC02

BUILD_DIR = build

BIN = build/sfs.bin

SFS_SOURCES = \
	main.s \
	sdcard.s \
	sfs.s \
	format.s \
	match.s
SFS_OBJECTS = $(addprefix $(BUILD_DIR)/, $(SFS_SOURCES:.s=.o))

all: clean $(BIN)

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	$(AS) $(ASFLAGS) -l $(BUILD_DIR)/$*.lst $< -o $@

$(BUILD_DIR)/sfs.raw: $(GIT_SIGNATURE) $(SFS_OBJECTS)
	@mkdir -p $$(dirname $@)
	$(LD) -C mem.cfg $(SFS_OBJECTS) -o $@ -m $(BUILD_DIR)/sfs.map -Ln $(BUILD_DIR)/sfs.sym
	$(TOP)/rom/scripts/relist.py $(BUILD_DIR)/sfs.map $(BUILD_DIR)

$(BUILD_DIR)/sfs.bin: $(BUILD_DIR)/sfs.raw
	python3 ../loadtrim.py build/sfs.raw build/sfs.bin
clean:
	rm -fr build