.PHONY: all clean

all: clean bin

bin:
	cl65 -t none -Ln hello.sym -C main.cfg -m hello.map -o hello.raw main.c exports.s
	python3 ../loadtrim.py hello.raw hello.bin
	rm -fr *.raw

clean:
	rm -f *.o *.bin *.raw *.lst *.map *.sym os.lib
