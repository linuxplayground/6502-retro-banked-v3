TOP = ../..

include $(TOP)/src/Make.rules

LIBSOURCES = 
LIBOBJECTS = $(LIBSOURCES:%=%.o)

SOURCES = main
OBJECTS = $(SOURCES:%=%.o)

BIN = conio_c

DEBUG=1

.PHONY: all clean always kernal

all: clean kernal $(BIN)
lib: clean $(LIBBIN)

clean:
	rm -fr build
always:
	mkdir -pv build
kernal: always
	ca65 $(CAFLAGS) -o build/kernal.o $(TOP)/libsrc/kernal.s

$(LIBOBJECTS): always
	ca65 $(CAFLAGS) -DDEBUG=$(DEBUG) -o build/$@ $(@:%.o=lib/%.s)

$(OBJECTS): always
	cc65 $(CCFLAGS) -o build/main.s main.c
	ca65 $(CAFLAGS) -DDEBUG=$(DEBUG) -o build/$@ $(@:%.o=build/%.s)

$(BIN):  $(LIBOBJECTS) $(OBJECTS) always
	ld65 $(LDFLAGS) -o build/$@.raw  build/main.o build/kernal.o $(LIBOBJECTS:%.o=build/%.o) $(LIB)
	python3 $(TOP)/loadtrim.py build/$@.raw build/$@.bin
