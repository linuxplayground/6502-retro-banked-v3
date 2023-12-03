
all: clean
	mkdir build
	ca65 -l build/save.lst -g --cpu 65C02 -I ../../rom/inc -o build/save.o main.s
	ld65 -Ln build/save.sym -m build/save.map -C mem.cfg -o build/save.raw build/save.o \
	`../../rom/findsymbols ../../rom/build/monitor.sym fat32_dirent fat32_errno fat32_readonly fat32_size skip_mask`
	python3 ../loadtrim.py build/save.raw build/save.bin

clean:
	rm -fr build