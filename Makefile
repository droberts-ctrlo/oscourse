all: boot.asm loader.asm
	@echo "Starting build process"
	@echo "Building Orion boot image"
	@nasm -f bin -o boot.bin boot.asm
	@echo "Building Orion loader"
	@nasm -f bin -o loader.bin loader.asm
	@echo "Writing loader to image"
	@dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
	@dd if=loader.bin of=boot.img bs=512 count=5 seek=1 conv=notrunc

clean:
	@rm -f boot.bin loader.bin
