all: hantow

hantow: hantow.o asm_io.o
	gcc -m32 -o hantow hantow.o driver.c asm_io.o

hantow.o: hantow.asm asm_io.inc
	nasm -f elf32 hantow.asm

asm_io.o: asm_io.asm
	nasm -f elf32 -d ELF_TYPE asm_io.asm

clean:
	rm hantow.o hantow

