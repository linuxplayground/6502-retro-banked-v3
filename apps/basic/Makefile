CC           = cc65
AS           = ca65
LD           = ld65

# global includes
ASFLAGS     += -I ../../rom/inc
# for monitor
# ASFLAGS     += -D CPU_65C02=1
# # put all symbols into .sym files
ASFLAGS     += -g
# # Allow labels without colons
# ASFLAGS     += --feature labels_without_colons
# all files are allowed to use 65SC02 features
ASFLAGS     += --cpu 65C02

ASFLAGS     += -U

# DEBUG = 1
# ASFLAGS     += -DDEBUG=$(DEBUG)

BUILD_DIR = build

BASIC_SOURCES = basic.s
BASIC_OBJS   = $(addprefix $(BUILD_DIR)/, $(BASIC_SOURCES:.s=.o))

all: $(BUILD_DIR)/basic.bin

$(BUILD_DIR)/basic.bin: $(BUILD_DIR)/basic.raw
	python3 loadtrim.py $(BUILD_DIR)/basic.raw $(BUILD_DIR)/basic.bin

clean:
	rm -fr $(BUILD_DIR)

MKDIRS: FORCE
	@mkdir -p $(BUILD_DIR)

FORCE:

$(BUILD_DIR)/%.cfg: %.cfgtpl
	@mkdir -p $$(dirname $@)
	$(CC) -E $< -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	$(AS) $(ASFLAGS) -l $(BUILD_DIR)/$*.lst $< -o $@

$(BUILD_DIR)/basic.raw: $(MKDIRS) $(BASIC_OBJS) basic.cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C basic.cfg $(BASIC_OBJS) -o $@ -m $(BUILD_DIR)/basic.map -Ln $(BUILD_DIR)/basic.sym