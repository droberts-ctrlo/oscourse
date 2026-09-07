[BITS 16]
[ORG 0x7e00]

start:
    mov [DriveID],dl ; Store the drive ID passed in DL

    mov eax,0x80000000 ; Set EAX to a specific value (example: memory address or flag)
    cpuid ; Execute the CPUID instruction to get CPU information
    cmp eax,0x80000001 ; Compare EAX with the specific value (example: memory address or flag)
    jb NotSupported ; Jump to NotSupported if the CPU does not support the required feature

    mov eax,0x80000001 ; Set EAX to the next specific value (example: memory address or flag)
    cpuid ; Execute the CPUID instruction again to get updated CPU information
    test edx, 1 << 29 ; Check if the specific feature (example: NX bit) is supported
    jz NotSupported ; Jump to NotSupported if the feature is not supported

    mov ah, 0x13 ; BIOS disk services function (example: extended read/write)
    mov al, 1 ; Number of sectors to read
    mov bx, 0xa ; Page number and attribute (example value)
    xor dx, dx ; clear DX register
    mov bp,Message ; Pointer to the message
    mov cx,MessageLength ; Length of the message
    int 0x10 ; BIOS interrupt to display the message

NotSupported:
End:
    hlt ; Halt the CPU
    jmp End ; Loop indefinitely after halting the CPU

Message db 'Welcome to Orion' ; Message to display
MessageLength equ $ - Message ; Length of the message
DriveID db 0 ; Store the drive ID passed in DL
