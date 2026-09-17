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

    cli
    lgdt [Gdt32Ptr]
    lidt [Idt32Ptr]

    mov eax, cr0 ; Load the control register CR0 into EAX
    or eax, 0x1 ; Set the PE (Protection Enable) bit in CR0 to enable protected mode
    mov cr0, eax ; Write back to CR0 to enable protected mode

    jmp 0x08:PMEntry

ReadError:
NotSupported:
End:
    hlt ; Halt the CPU
    jmp End ; Loop indefinitely after halting the CPU

[BITS 32]
PMEntry:
    mov ax, 0x10 ; Set AX to the video mode (0x10 for 80x25 text mode)
    mov ds, ax ; Set DS to the video mode segment (0x10 for 80x25 text mode)
    mov es, ax ; Set ES to the video mode segment (0x10 for 80x25 text mode)
    mov ss, ax ; Set SS to the video mode segment (0x10 for 80x25 text mode)
    mov esp, 0x7c00 ; Set ESP to the top of the bootloader stack area

    cld ; clear direction flag
    mov edi, 0x70000 ; Set EDI to the start of the memory copy destination
    xor eax, eax ; Clear EAX register before starting the memory copy
    mov ecx, 0x10000/4 ; Set ECX to the number of double words to copy (0x10000 bytes / 4 bytes per double word)
    rep stosd ; Repeat storing EAX into the memory destination pointed by EDI for ECX times

    mov dword[0x70000], 0x71007 ; Initialize the first double word of the memory copy destination to 0
    mov dword[0x71000], 10000111b ; Initialize the second double word of the memory copy destination to 10000111b

    lgdt [Gdt32Ptr] ; Load the GDT pointer into the GDTR register

    mov eax, cr4 ; Load the control register CR4 into EAX
    or eax, (1<<5) ; Set the PAE (Physical Address Extension) bit in CR4
    mov cr4, eax ; Write back to CR4 to enable PAE

    mov eax, 0x70000 ; Load the base address of the memory copy destination into EAX
    mov cr3, eax ; Load the base address of the memory copy destination into CR3 for paging

    mov ecx, 0xc0000080 ; Load the address of the MSR (Model-Specific Register) for enabling PAE into ECX
    rdmsr ; Read the MSR into EDX:EAX
    or eax, (1<<8) ; Set the NXE (No-Execute Enable) bit in the MSR
    wrmsr ; Write the updated value back to the MSR

    mov eax, cr0 ; Load the control register CR0 into EAX
    or eax, (1<<31) ; Set the PG (Paging) bit in CR0 to enable paging
    mov cr0, eax ; Write back to CR0 to enable paging

    jmp 0x8:LMEntry

PEnd:
    hlt ; Halt the CPU
    jmp PEnd ; Loop indefinitely after halting the CPU

[BITS 64]
LMEntry:
    mov rsp, 0x7c00 ; Set RSP to the top of the bootloader stack area

    lea rsi, [Message] ; Load the address of the message into RSI
    mov rdi, 0xb8000 ; Set RDI to the start of the VGA text buffer

MessageLoop:
    mov al, [rsi] ; Load the next character from the message into AL
    cmp al, 0 ; Check if the character is the null terminator
    je LEnd ; If the character is the null terminator, jump to the end of the message

    mov [rdi], al ; Store the character in the VGA text buffer
    mov byte [rdi+1], 0x0a ; Set the color attribute for the character to white on black
    add rsi, 1 ; Move to the next character in the message
    add rdi, 2 ; Move to the next character position in the VGA text buffer
    jmp MessageLoop ; Repeat the loop for the next character

LEnd:
    hlt ; Halt the CPU
    jmp LEnd ; Loop indefinitely after halting the CPU

DriveID db 0 ; Store the drive ID passed in DL
ReadPacket times 16 db 0 ; Disk read packet

Message db 'Welcome to Orion...', 0 ; Message to display

Gdt32:
    dq 0x0 ; Null descriptor for the GDT
Code32:
    dw 0xFFFF ; Limit low for the code segment
    dw 0 ; Base low for the code segment
    db 0 ; Base middle for the code segment
    db 0x9a ; Access byte for the code segment
    db 0xcf ; 
    db 0 ; Base high for the code segment
Data32:
    dw 0xFFFF ; Limit low for the code segment
    dw 0 ; Base low for the code segment
    db 0 ; Base middle for the code segment
    db 0x92 ; Access byte for the data segment
    db 0xcf ; 
    db 0 ; Base high for the code segment

Gdt32Len: equ $ - Gdt32

Gdt32Ptr: dw Gdt32Len - 1 ; Limit for the GDT
          dd Gdt32 ; Base address for the GDT

Idt32Ptr: dw 0 ; Limit for the IDT
          dd 0 ; Base address for the IDT

Gdt64:
    dq 0x0 ; Null descriptor for the GDT
    dq 0x0020980000000000 ; Code segment descriptor for 64-bit code

Gdt64Len: equ $ - Gdt64

Gdt64Ptr: dw Gdt64Len - 1 ; Limit for the GDT
          dd Gdt64 ; Base address for the GDT
