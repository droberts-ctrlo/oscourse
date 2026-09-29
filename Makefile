# Variables for compilers and flags
NASM    = nasm
CC      = gcc
LD      = ld
OBJCOPY = objcopy
DD      = dd

CFLAGS  = -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c
LDFLAGS = -nostdlib -T link.lds

# Target image and its dependencies
TARGET  = boot.img
OBJS    = kernel.o main.o trapa.o trap.o
BINS    = boot.bin loader.bin kernel.bin

# Default target
all: $(TARGET)

# Create the final bootable disk image
$(TARGET): boot.bin loader.bin kernel.bin
	# Initialize/copy boot.bin to the start of the image
	$(DD) if=boot.bin of=$(TARGET) bs=512 count=1 conv=notrunc
	# Append loader.bin right after the boot sector
	$(DD) if=loader.bin of=$(TARGET) bs=512 count=5 seek=1 conv=notrunc
	# Append kernel.bin at sector 6
	$(DD) if=kernel.bin of=$(TARGET) bs=512 count=100 seek=6 conv=notrunc

# Link the kernel binary
kernel.bin: kernel
	$(OBJCOPY) -O binary kernel kernel.bin

kernel: $(OBJS)
	$(LD) $(LDFLAGS) -o kernel $(OBJS)

# Pattern rule for raw binary assembly files (boot and loader)
%.bin: %.asm
	$(NASM) -f bin -o $@ $<

# Rules for 64-bit ELF assembly objects
kernel.o: kernel.asm
	$(NASM) -f elf64 -o $@ $<

trapa.o: trap.asm
	$(NASM) -f elf64 -o $@ $<

# Pattern rule for C source files
%.o: %.c
	$(CC) $(CFLAGS) -o $@ $<

# Clean up build artifacts
clean:
	rm -f $(BINS) $(OBJS) kernel
	git checkout $(TARGET)

.PHONY: all clean
