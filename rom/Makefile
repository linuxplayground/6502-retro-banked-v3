CC           = cc65
AS           = ca65
LD           = ld65

# global includes
ASFLAGS     += -I inc
# for monitor
ASFLAGS     += -D CPU_65C02=1
# put all symbols into .sym files
ASFLAGS     += -g
# all files are allowed to use 65SC02 features
ASFLAGS     += --cpu 65SC02

BUILD_DIR = build
CFG_DIR=$(BUILD_DIR)/cfg

KERN_CORE_SOURCES = \
	kern/kernzp.s

DRIVER_SOURCES = \
	kern/acia.s

KERN_SOURCES = \
	$(KERN_CORE_SOURCES) \
	$(DRIVER_SOURCES)

MONITOR_SOURCES = \
	monitor/mon.s \
	$(KERN_SOURCES)

MONITOR_OBJS = $(addprefix $(BUILD_DIR)/, $(MONITOR_SOURCES:.s=.o))

BANK_BINS = \
	$(BUILD_DIR)/monitor.bin

GENERIC_DEPS = \
	inc/io.inc

KERN_DEPS = \
	$(GENERIC_DEPS) \
	$(GIT_SIGNATURE)

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

$(BUILD_DIR)/monitor.bin: $(GIT_SIGNATURE) $(MONITOR_OBJS) $(MONITOR_DEPS) $(CFG_DIR)/monitor.cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C $(CFG_DIR)/monitor.cfg $(MONITOR_OBJS) -o $@ -m $(BUILD_DIR)/monitor.map -Ln $(BUILD_DIR)/monitor.sym
	./scripts/relist.py $(BUILD_DIR)/monitor.map $(BUILD_DIR)/monitor
	./scripts/relist.py $(BUILD_DIR)/monitor.map $(BUILD_DIR)/kern