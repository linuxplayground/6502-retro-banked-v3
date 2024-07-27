CC           = cc65
AS           = ca65
LD           = ld65

# global includes
ASFLAGS     += -I inc
# for monitor
ASFLAGS     += -D CPU_65C02=1
# put all symbols into .sym files
ASFLAGS     += -g
# Allow labels without colons
ASFLAGS     += --feature labels_without_colons
# all files are allowed to use 65SC02 features
ASFLAGS     += --cpu 65SC02

# DEBUG = 1
# ASFLAGS     += -DDEBUG=$(DEBUG)

BUILD_DIR = build
CFG_DIR=$(BUILD_DIR)/cfg

KERN_CORE_SOURCES = \
	kern/kernzp.s \
	kern/memory.s \
	kern/sn76489.s \
	kern/primm.s \
	kern/vdp.s \
	kern/tty.s \
	kern/jmptbl.s

DRIVER_SOURCES = \
	kern/acia.s

KERN_SOURCES = \
	$(KERN_CORE_SOURCES) \
	$(DRIVER_SOURCES)

SFS_SOURCES  = \
	sfs/sdcard.s \
	sfs/format.s \
	sfs/match.s \
	sfs/sfs.s

MONITOR_SOURCES = \
	$(SFS_SOURCES) \
	monitor/doszp.s \
	monitor/dosmem.s \
	monitor/dos.s \
	monitor/convert_error.s \
	monitor/bin2bcd.s \
	monitor/readline.s \
	monitor/mon.s \
	monitor/wozmon.s \
	monitor/xmodem.s \
	$(KERN_SOURCES)

BASIC_SOURCES = \
	kern/kernzp.s \
	basic/min_mon.s

MONITOR_OBJS = $(addprefix $(BUILD_DIR)/, $(MONITOR_SOURCES:.s=.o))
BASIC_OBJS   = $(addprefix $(BUILD_DIR)/, $(BASIC_SOURCES:.s=.o))

BANK_BINS = \
	$(BUILD_DIR)/monitor.bin \
	$(BUILD_DIR)/basic.bin \
	/mnt/d/Hopper/Bin/r6502.bin \
	./smon/build/smon.bin


GENERIC_DEPS = \
	inc/io.inc

KERN_DEPS = \
	$(GENERIC_DEPS) \
	$(GIT_SIGNATURE)

BASIC_DEPS = 

GIT_SIGNATURE=$(BUILD_DIR)/../signature.bin
all: $(BUILD_DIR)/rom.bin

$(BUILD_DIR)/rom.bin: $(BANK_BINS)
	cat $(BANK_BINS) > $@

clean:
	rm -f $(GIT_SIGNATURE)
	rm -rf $(BUILD_DIR)

$(GIT_SIGNATURE): FORCE
	@mkdir -p $(BUILD_DIR)
	git diff --quiet && /bin/echo -n $$( (git rev-parse --short=8 HEAD || /bin/echo "00000000") | tr '[:lower:]' '[:upper:]') > $(GIT_SIGNATURE) \
	|| /bin/echo -n $$( /bin/echo -n $$(git rev-parse --short=7 HEAD || echo "0000000") | tr '[:lower:]' '[:upper:]'; /bin/echo -n '+') > $(GIT_SIGNATURE)

FORCE:

$(BUILD_DIR)/%.cfg: %.cfgtpl
	@mkdir -p $$(dirname $@)
	$(CC) -E $< -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	$(AS) $(ASFLAGS) -l $(BUILD_DIR)/$*.lst $< -o $@

# BANK 0 - Monitor and kernel
$(BUILD_DIR)/monitor.bin: $(GIT_SIGNATURE) $(MONITOR_OBJS) $(MONITOR_DEPS) $(CFG_DIR)/monitor.cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C $(CFG_DIR)/monitor.cfg $(MONITOR_OBJS) -o $@ -m $(BUILD_DIR)/monitor.map -Ln $(BUILD_DIR)/monitor.sym
	./scripts/relist.py $(BUILD_DIR)/monitor.map $(BUILD_DIR)/monitor
	./scripts/relist.py $(BUILD_DIR)/monitor.map $(BUILD_DIR)/kern

# BANK 1 - Basic
$(BUILD_DIR)/basic.bin: $(GIT_SIGNATURE) $(BASIC_OBJS) $(BASIC_DEPS) $(CFG_DIR)/basic.cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C $(CFG_DIR)/basic.cfg $(BASIC_OBJS) -o $@ -m $(BUILD_DIR)/basic.map -Ln $(BUILD_DIR)/basic.sym
	./scripts/relist.py $(BUILD_DIR)/basic.map $(BUILD_DIR)/basic

minipro:
	 minipro -s -p SST27SF512@DIP28 -w $(BUILD_DIR)/rom.bin
