[BITS 16]
[ORG 0x7C00]

start:
    xor ax,ax ; Set all values to 0
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,0x7C00 ; Set stack pointer to top of boot sector

TestDiskExtension:
    mov [DriveId], dl ; Store the drive ID for later use
    mov ah, 0x41 ; Check for extended disk services support
    mov bx, 0x55aa ; Signature for extended disk services
    int 0x13
    jc NotSupported ; Jump if carry flag is set (error)
    cmp bx, 0xaa55 ; Check if the signature is correct
    jne NotSupported ; Jump if not supported

LoadLoader:
    mov si, ReadPacket
    mov word[si], 0x10 ; Set size of the read packet
    mov word[si+2], 5 ; Number of sectors to read
    mov word[si+4], 0x7e00 ; Segment address to load the sectors
    mov word[si+6], 0 ; Offset address to load the sectors
    mov dword[si+8], 1 ; Starting LBA sector
    mov dword[si+0xc], 0 ; Reserved, set to 0
    mov dl, [DriveId] ; Set the drive ID for the read operation
    mov ah, 0x42 ; Extended read sectors from drive
    int 0x13 ; Call BIOS to read sectors
    jc ReadError ; Jump if there was an error reading sectors

    mov dl, [DriveId]
    jmp 0x7e00 ; Jump to the loaded code

ReadError: ; Label for handling read errors
NotSupported: ; Label for handling unsupported disk services
    mov ah,0x13 ; BIOS teletype output function
    mov al,1 ; Number of characters to write
    mov bx,0xa ; Page number and attribute
    xor dx,dx ; Row and column
    mov bp,Message ; Pointer to the message
    mov cx,MessageLength ; Length of the message
    int 0x10 ; Call BIOS to display the message
    jmp End

End:
    hlt ; Halt the CPU
    jmp End ; Loop indefinitely after halting the CPU

DriveId db 0 ; Store the drive ID for later use
Message db 'Error in boot loader' ; Error message to display
MessageLength equ $ - Message ; Length of the error message
ReadPacket times 16 db 0 ; Buffer for the extended read packet structure

times (0x1be - ($ - $$)) db 0 ; Fill the rest of the boot sector up to the partition table

    db 80h ; Bootable flag for the first partition
    db 0,2,0 ; CHS address of the first sector
    db 0f0h ; Partition type
    db 0ffh,0ffh,0ffh ; CHS address of the last sector
    dd 1 ; LBA of the first sector
    dd (20*16*63-1) ; Number of sectors in the partition

    times (16 * 3) db 0 ; Reserved space for additional partition entries

    db 0x55 ; Boot sector signature
    db 0xaa ; Boot sector signature


