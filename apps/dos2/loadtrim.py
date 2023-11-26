import sys

in_file=open(sys.argv[1], "rb")
out_file=open(sys.argv[2], "wb")

binary_input=in_file.read()
in_file.close()
out_file.write(bytearray(b'\x00\x90'))
out_file.write(binary_input)
out_file.close()

