# Variables for tools and flags
NASM    = nasm
CC      = gcc
LD      = ld
OBJCOPY = objcopy
DD      = dd

CFLAGS  = -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c
LDFLAGS = -nostdlib -T link.lds

# Target image
IMAGE   = boot.img

# Lists of object files
ASM_OBJS = kernel.o trapa.o liba.o
C_OBJS   = main.o trap.o print.o debug.o
ALL_OBJS = $(ASM_OBJS) $(C_OBJS)

# Phony targets
.PHONY: all clean

# Default rule
all: $(IMAGE)

# Rule to create the final boot image
$(IMAGE): boot.bin loader.bin kernel.bin
	$(DD) if=boot.bin of=$(IMAGE) bs=512 count=1 conv=notrunc
	$(DD) if=loader.bin of=$(IMAGE) bs=512 count=5 seek=1 conv=notrunc
	$(DD) if=kernel.bin of=$(IMAGE) bs=512 count=100 seek=6 conv=notrunc

# Rules for raw binaries
boot.bin: boot.asm
	$(NASM) -f bin -o $@ $<

loader.bin: loader.asm
	$(NASM) -f bin -o $@ $<

kernel.bin: kernel
	$(OBJCOPY) -O binary $< $@

# Rule to link the kernel elf
kernel: $(ALL_OBJS)
	$(LD) $(LDFLAGS) -o $@ $(ALL_OBJS)

# Rules for Assembly object files (ELF64)
kernel.o: kernel.asm
	$(NASM) -f elf64 -o $@ $<

trapa.o: trap.asm
	$(NASM) -f elf64 -o $@ $<

liba.o: lib.asm
	$(NASM) -f elf64 -o $@ $<

# Implicit rule for C object files
%.o: %.c
	$(CC) $(CFLAGS) -o $@ $<

# Clean up build files
clean:
	rm -f *.o *.bin kernel
	git checkout $(IMAGE)
