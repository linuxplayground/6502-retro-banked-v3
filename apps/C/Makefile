.PHONY: all clean

all: clean
	cl65 -t none -C main.cfg -l hello.lst -m hello.map -o hello.raw main.c exports.s
	python3 ../loadtrim.py hello.raw hello.bin

clean:
	rm -f *.o *.bin *.raw *.lst *.map
