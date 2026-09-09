[BITS 16]
[ORG 0x7e00]

start:
    mov [DriveID],dl ; Store the drive ID passed in DL

    mov eax,0x80000000 ; Set EAX to the extended CPUID function range
    cpuid ; Execute the CPUID instruction to get CPU information
    cmp eax,0x80000001 ; Check if the CPU supports the extended CPUID function 0x80000001 (extended features)
    jb NotSupported ; Jump to NotSupported if the CPU does not support the required feature

    mov eax,0x80000001 ; Set EAX to the extended CPUID function 0x80000001 to check for extended features
    cpuid ; Execute the CPUID instruction again to get updated CPU information
    test edx, 1 << 29 ; Check if the long mode (64-bit) feature is supported
    jz NotSupported ; Jump to NotSupported if the feature is not supported
    test edx, 1 << 26 ; Check if the 1GB page support feature is available
    jz NotSupported ; Jump to NotSupported if the feature is not supported

LoadKernel:
    mov si, ReadPacket ; Create a pointer to the disk read packet
    mov word[si], 0x10 ; Set the size of the disk read packet
    mov word[si+2], 100 ; Set the number of sectors to read
    mov word[si+4], 0 ; Set the segment of the memory buffer
    mov word[si+6], 0x1000 ; Set the offset of the memory buffer
    mov dword[si+8], 6 ; Set the starting LBA
    mov dword[si+0xc], 0 ; Set the next field of the disk read packet
    mov dl, [DriveID] ; Load the drive ID into DL
    mov ah, 0x42 ; BIOS extended read function
    int 0x13 ; Call BIOS disk services to perform the read
    jc ReadError ; Jump to ReadError if the disk read fails

    mov ah, 0x13 ; BIOS disk services function (extended read/write)
    mov al, 1 ; Number of sectors to read
    mov bx, 0xa ; Page number and attribute
    xor dx, dx ; clear DX register
    mov bp,Message ; Pointer to the message
    mov cx,MessageLength ; Length of the message
    int 0x10 ; BIOS interrupt to display the message

ReadError:
NotSupported:
End:
    hlt ; Halt the CPU
    jmp End ; Loop indefinitely after halting the CPU

Message db 'Kernel Loaded' ; Message to display
MessageLength equ $ - Message ; Length of the message
DriveID db 0 ; Store the drive ID passed in DL
ReadPacket times 16 db 0 ; Disk read packet