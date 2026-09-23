# Variables for Compilers and Flags
NASM    = nasm
CC      = gcc
LD      = ld
OBJCOPY = objcopy
DD      = dd
BOCHS   = bochs

CFLAGS  = -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c
LDFLAGS = -nostdlib -T link.lds

# Targets
.PHONY: all clean run

all: boot.img

# Build the final OS disk image
boot.img: boot.bin loader.bin kernel.bin
	@echo "Creating disk image..."
	@$(DD) if=boot.bin of=$@ bs=512 count=1 conv=notrunc
	@$(DD) if=loader.bin of=$@ bs=512 count=5 seek=1 conv=notrunc
	@$(DD) if=kernel.bin of=$@ bs=512 count=100 seek=6 conv=notrunc

# Bootloader stage 1
boot.bin: boot.asm
	@$(NASM) -f bin -o $@ $<

# Bootloader stage 2 (loader)
loader.bin: loader.asm
	@$(NASM) -f bin -o $@ $<

# Kernel binary extracted from the linked ELF
kernel.bin: kernel
	@$(OBJCOPY) -O binary $< $@

# Linked kernel ELF file
kernel: kernel.o main.o
	@$(LD) $(LDFLAGS) -o $@ $^

# Kernel assembly file
kernel.o: kernel.asm
	@$(NASM) -f elf64 -o $@ $<

# Kernel C file
main.o: main.c
	@$(CC) $(CFLAGS) -o $@ $<

run: boot.img
	@echo "Launching Bochs..."
	$(BOCHS) -q

# Clean up build artifacts
clean:
	git checkout boot.img
	rm -f *.bin *.o kernel bochsrc.txt bochsout.txt
