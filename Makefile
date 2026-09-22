assembler = nasm
writer = dd
name = Orion
image = boot.img
runner = bochs
args = ""

all: boot.asm loader.asm
	@echo "Starting build process"
	@echo "Building $(name) boot image"
	@$(assembler) -f bin -o boot.bin boot.asm
	@echo "Building $(name) loader"
	@$(assembler) -f bin -o loader.bin loader.asm
	@echo "Writing loader to image"
	@$(writer) if=boot.bin of=$(image) bs=512 count=1 conv=notrunc
	@$(writer) if=loader.bin of=$(image) bs=512 count=5 seek=1 conv=notrunc

run: all
	@$(runner) $(args)

clean:
	@rm -f *.bin
	@git checkout $(image)
