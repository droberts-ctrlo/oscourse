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

GetMemInfoStart:
    mov eax, 0xe820
    mov edx, 0x534d4150 ; 'SMAP' signature for the e820 memory map
    mov ecx, 20 ; Size of the buffer for the e820 memory map entry
    mov edi, 0x9000 ; Set the destination buffer for the e820 memory map entry
    xor ebx, ebx ; Clear EBX register for the e820 memory map continuation value
    int 0x15 ; BIOS interrupt to get the e820 memory map entry
    jc NotSupported ; Jump to NotSupported if the e820 memory map retrieval fails

GetMemInfo:
    add edi, 20 ; Move to the next e820 memory map entry
    mov eax, 0xe820 ; Set EAX to the e820 memory map function
    mov edx, 0x534d4150 ; 'SMAP' signature for the e820 memory map
    mov ecx, 20 ; Size of the buffer for the e820 memory map entry
    int 0x15 ; BIOS interrupt to get the e820 memory map entry
    jc GetMemDone ; Jump to GetMemDone if the e820 memory map retrieval is complete

    test ebx, ebx ; Check if there are more e820 memory map entries
    jnz GetMemInfo ; Jump to GetMemInfo if there are more entries

GetMemDone:
TestA20:
    mov ax, 0xffff ; Set AX to 0xFFFF to test the A20 line
    mov es, ax ; Set ES to 0xFFFF to test the A20 line
    mov word[ds:0x7c00], 0xa200 ; Store the test value for the A20 line
    cmp word[es:0x7c00], 0xa200 ; Compare the test value for the A20 line
    jne SetA20LineDone ; Jump to SetA20LineDone if the A20 line test fails
    mov word[0x7c00], 0xb200 ; Refresh the test value for the A20 line
    mov word[es:0x7c00], 0xb200 ; Refresh the test value for the A20 line
    je End ; Jump to End if the A20 line test passes

SetA20LineDone:
    xor ax, ax ; Clear AX register after setting the A20 line
    mov es, ax ; Clear ES register after setting the A20 line

SetVideoMode:
    mov ax, 3 ; Set video mode to 80x25 text mode
    int 0x10 ; BIOS interrupt to set the video mode

    mov si, Message ; Set SI to point to the message to display
    mov ax, 0xb800 ; Set AX to the segment address for text mode video memory
    mov es, ax ; Set ES to the segment address for text mode video memory
    xor di, di ; Clear DI register to start writing at the beginning of the video memory segment
    mov cx, MessageLength ; Set CX to the length of the message

PrintMessage:
    mov al, [si] ; Load the next character of the message into AL
    mov [es:di], al ; Store the character in video memory
    mov byte[es:di+1], 0xa ; Set the attribute for the character in video memory

    add di, 2 ; Move to the next character position in video memory
    add si, 1 ; Move to the next character in the message
    loop PrintMessage ; Loop until all characters of the message are displayed

ReadError:
NotSupported:
End:
    hlt ; Halt the CPU
    jmp End ; Loop indefinitely after halting the CPU

Message db 'Welcome to Orion...' ; Message to display
MessageLength equ $ - Message ; Length of the message
DriveID db 0 ; Store the drive ID passed in DL
ReadPacket times 16 db 0 ; Disk read packet
