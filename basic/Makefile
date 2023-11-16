CA65=ca65
LD65=ld65

.PHONY: all clean

objects =  bank.o acia.o ../build/lib/os.lib

all: clean bank.o acia.o min_mon.o basic.bin

basic.bin:
	$(LD65) -o $@ \
		-m basic.map \
		-C ../cfg/rom.cfg \
		min_mon.o \
		$(objects)
		

min_mon.o: min_mon.s 6502-retro-basic.s basic.s
	$(CA65) --cpu 65C02 -I ../inc -l basic.lst --feature labels_without_colons min_mon.s

bank.o:
	$(CA65) --cpu 65C02 -I ../inc -o $@ ../lib/bank.s
acia.o:
	$(CA65) --cpu 65C02 -I ../inc -o $@ ../lib/acia.s
clean:
	rm -f min_mon.o bank.o basic.bin *.lst *.map

