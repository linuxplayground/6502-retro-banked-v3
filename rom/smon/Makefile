.PHONY: all
all: clean
	mkdir -pv build
	./vasm6502_oldstyle -wdc02 -dotdir -Fbin -L build/smon.lst -Lall -o build/smon.bin smon.s
clean:
	rm -fr build
