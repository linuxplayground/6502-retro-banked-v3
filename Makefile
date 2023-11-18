load_lib_sources = crt0.s

load_lib_objects = $(load_lib_sources:%.s=%.o)

lib         =   build/lib/os.lib

lib_sources = 	acia.s \
		bank.s \
		conio.s \
		kernal.s \
		sysram.s \
		utils.s \
		via.s \
		wozmon.s \
		xmodem.s \
		zeropage.s
lib_objects =   $(lib_sources:%.s=%.o)

rom_sources = 	retromon.s
rom_objects = 	$(rom_sources:%.s=%.o)
rom_bins    =   $(rom_sources:%.s=%.bin)


basic_sources = min_mon.s
basic_objects = min_mon.o
basic_bins = basic.bin

.PHONY: all clean

all: clean build_dirs $(lib) $(rom_bins) $(basic_bins)

# LIB
$(load_lib_objects):
	ca65 --cpu 65c02 -DDEBUG=0 -l $(@:%.o=build/lib/%.lst) -I inc -o $(@:%.o=build/lib/%.o) $(@:%.o=lib/%.s)
$(lib): $(load_lib_objects) sysram.o zeropage.o
	cp -f cfg/none.lib build/lib/os.lib
	ar65 a build/lib/os.lib $(^:%.o=build/lib/%.o)
# ROM
$(lib_objects):
	ca65 --cpu 65c02 -DDEBUG=0 -l $(@:%.o=build/lib/%.lst) -I inc -o $(@:%.o=build/lib/%.o) $(@:%.o=lib/%.s)
$(rom_objects): $(lib_objects)
	ca65 --cpu 65c02 -DDEBUG=0 -l $(@:%.o=build/retromon/%.lst) -I inc -o $(@:%.o=build/retromon/%.o) $(@:%.o=retromon/%.s)
$(rom_bins): $(rom_objects)
	cc65 -E cfg/rom.cfgtpl -o build/rom.cfg
	ld65 -C build/rom.cfg -Ln $(@:%.bin=build/retromon/%.lnk) -m $(@:%.bin=build/retromon/%.map) -o $(@:%.bin=build/retromon/%.bin) $(@:%.bin=build/retromon/%.o) $(lib_objects:%.o=build/lib/%.o) $(lib)
# BASIC
$(basic_objects):
	ca65 --feature labels_without_colons --cpu 65c02 -DDEBUG=0 -l $(@:%.o=build/basic/%.lst) -I inc -o $(@:%.o=build/basic/%.o) $(@:%.o=basic/%.s)
$(basic_bins): $(basic_objects)
	cc65 -E cfg/basic.cfgtpl -o build/basic.cfg
	ld65 -C build/basic.cfg -Ln $(@:%.bin=build/basic/%.lnk) -m $(@:%.bin=build/basic/%.map) -o $(@:%.bin=build/basic/%.bin) build/basic/min_mon.o build/lib/zeropage.o

build_dirs:
	mkdir -pv build/retromon
	mkdir -pv build/lib
	mkdir -pv build/basic

minipro:
	minipro -p SST27SF512@DIP28 -s -w build/combined.bin
clean:
	rm -fr build

world:
	$(MAKE) all
	cat build/retromon/retromon.bin build/basic/basic.bin > build/combined.bin
