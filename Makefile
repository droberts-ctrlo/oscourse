# Variables
NASM      := nasm
DD        := dd
GIT       := git
BOCHS     := bochs
BOCHSFLAGS:= 

NAME      := Orion
IMAGE     := boot.img
BINS      := boot.bin loader.bin

# Phony Targets
.PHONY: all run clean

# Default Target
all: $(IMAGE)

# Link binaries into the final boot image
$(IMAGE): $(BINS)
	@echo "Creating $(NAME) boot image..."
	@$(GIT) checkout $(IMAGE)
	@$(DD) if=boot.bin of=$@ bs=512 count=1 conv=notrunc
	@$(DD) if=loader.bin of=$@ bs=512 count=5 seek=1 conv=notrunc

# Compiling Assembly files
%.bin: %.asm
	@echo "Assembling $<..."
	@$(NASM) -f bin -o $@ $<

# Emulate
run: all
	@$(BOCHS) $(BOCHSFLAGS)

# Clean build artifacts
clean:
	@echo "Cleaning workspace..."
	@rm -f $(BINS)
	@$(GIT) checkout $(IMAGE)
