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

rom_sources = 	6502-rom.s
rom_objects = 	$(rom_sources:%.s=%.o)
rom_bins    =   $(rom_sources:%.s=%.bin)

.PHONY: all clean

all: clean build_dirs $(lib) $(rom_bins)

$(load_lib_objects):
	ca65 --cpu 65c02 -DDEBUG=0 -l $(@:%.o=build/lib/%.lst) -I inc -o $(@:%.o=build/lib/%.o) $(@:%.o=lib/%.s)

$(lib_objects):
	ca65 --cpu 65c02 -DDEBUG=0 -l $(@:%.o=build/lib/%.lst) -I inc -o $(@:%.o=build/lib/%.o) $(@:%.o=lib/%.s)

$(rom_objects): $(lib_objects)
	ca65 --cpu 65c02 -DDEBUG=0 -l $(@:%.o=build/rom/%.lst) -I inc -o $(@:%.o=build/rom/%.o) $(@:%.o=rom/%.s)

$(lib): $(load_lib_objects) sysram.o zeropage.o
	cp -f cfg/none.lib build/lib/os.lib
	ar65 a build/lib/os.lib $(^:%.o=build/lib/%.o)

$(rom_bins): $(rom_objects)
	ld65 -C cfg/rom.cfg -Ln $(@:%.bin=build/rom/%.lnk) -m $(@:%.bin=build/rom/%.map) -o $(@:%.bin=build/rom/%.bin) $(@:%.bin=build/rom/%.o) $(lib_objects:%.o=build/lib/%.o) $(lib)

build_dirs:
	mkdir -pv build/rom
	mkdir -pv build/lib

minipro:
	minipro -p SST27SF512@DIP28 -s -w build/combined.bin
clean:
	rm -fr build

world:
	$(MAKE) all
	cd basic && $(MAKE) all
	cat build/rom/6502-rom.bin basic/basic.bin > build/combined.bin
