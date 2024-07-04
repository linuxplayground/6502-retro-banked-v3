.PHONY: all clean
AS = ca65

all: clean exports.o vdp_wrappers.o

%.o: %s
	ca65 --cpu 65c02 $< -o $@

clean:
	rm -f *.o

