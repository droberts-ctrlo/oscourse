# Variables
NASM = nasm
GCC = gcc
LD = ld
OBJCOPY = objcopy
DD = dd

# Flags
NASM_BIN_FLAGS = -f bin
NASM_ELF_FLAGS = -f elf64
GCC_FLAGS = -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c
LD_FLAGS = -nostdlib -T link.lds

# Targets
all: boot.img

boot.img: boot.bin loader.bin kernel.bin
	$(DD) if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
	$(DD) if=loader.bin of=boot.img bs=512 count=5 seek=1 conv=notrunc
	$(DD) if=kernel.bin of=boot.img bs=512 count=100 seek=6 conv=notrunc

boot.bin: boot.asm
	$(NASM) $(NASM_BIN_FLAGS) -o boot.bin boot.asm

loader.bin: loader.asm
	$(NASM) $(NASM_BIN_FLAGS) -o loader.bin loader.asm

kernel.bin: kernel
	$(OBJCOPY) -O binary kernel kernel.bin

kernel: kernel.o main.o trapa.o trap.o liba.o
	$(LD) $(LD_FLAGS) -o kernel kernel.o main.o trapa.o trap.o liba.o

kernel.o: kernel.asm
	$(NASM) $(NASM_ELF_FLAGS) -o kernel.o kernel.asm

trapa.o: trap.asm
	$(NASM) $(NASM_ELF_FLAGS) -o trapa.o trap.asm

liba.o: lib.asm
	$(NASM) $(NASM_ELF_FLAGS) -o liba.o lib.asm

main.o: main.c
	$(GCC) $(GCC_FLAGS) main.c -o main.o

trap.o: trap.c
	$(GCC) $(GCC_FLAGS) trap.c -o trap.o

clean:
	rm -f *.bin *.o kernel
	git checkout boot.img

.PHONY: all clean
