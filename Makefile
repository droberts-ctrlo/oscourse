# Variables
ASM = nasm
CC = gcc
LD = ld
OBJCOPY = objcopy
DD = dd

CFLAGS = -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c

# Default target
all: boot.img

# Create the final OS image
boot.img: boot.bin loader.bin kernel.bin
	$(DD) if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
	$(DD) if=loader.bin of=boot.img bs=512 count=5 seek=1 conv=notrunc
	$(DD) if=kernel.bin of=boot.img bs=512 count=100 seek=6 conv=notrunc

# Compile flat binaries
boot.bin: boot.asm
	$(ASM) -f bin -o boot.bin boot.asm

loader.bin: loader.asm
	$(ASM) -f bin -o loader.bin loader.asm

# Link and extract the kernel
kernel.bin: kernel.o main.o link.lds
	$(LD) -nostdlib -T link.lds -o kernel kernel.o main.o
	$(OBJCOPY) -O binary kernel kernel.bin

# Compile kernel components
kernel.o: kernel.asm
	$(ASM) -f elf64 -o kernel.o kernel.asm

main.o: main.c
	$(CC) $(CFLAGS) main.c

# Clean rule to clear built files
clean:
	rm -f *.bin *.o kernel
	git checkout boot.img

.PHONY: all clean
