[BITS 16]
[ORG 0x7e00]

start:
    mov [DriveId],dl ; Store the drive ID passed by the BIOS into the DriveId variable

    mov eax,0x80000000 ; Get the highest extended function supported by CPUID
    cpuid ; Call CPUID with EAX=0x80000000 to get the highest extended function supported
    cmp eax,0x80000001 ; Check if the highest extended function supported is at least 0x80000001
    jb NotSupport ; Jump to NotSupport if the highest extended function is less than 0x80000001

    mov eax,0x80000001 ; Get extended feature flags
    cpuid ; Call CPUID with EAX=0x80000001 to get extended feature flags
    test edx,(1<<29) ; Check if the CPU supports LM (Long Mode)
    jz NotSupport ; Jump to NotSupport if LM is not supported
    test edx,(1<<26) ; Check if the CPU supports NX (No-Execute)
    jz NotSupport ; Jump to NotSupport if NX is not supported

LoadKernel:
    mov si,ReadPacket ; Load the address of the ReadPacket structure into SI
    mov word[si],0x10 ; Set the size of the packet structure
    mov word[si+2],100 ; Set the number of sectors to read
    mov word[si+4],0 ; Set the segment of the buffer
    mov word[si+6],0x1000 ; Set the offset of the buffer
    mov dword[si+8],6 ; Set the drive number
    mov dword[si+0xc],0 ; Set the reserved field
    mov dl,[DriveId] ; Load the drive ID into DL for the BIOS interrupt call
    mov ah,0x42 ; BIOS extended read sectors function
    int 0x13 ; Call BIOS interrupt to read sectors
    jc  ReadError ; Jump to ReadError if the carry flag is set

GetMemInfoStart:
    mov eax,0xe820 ; Get memory map using BIOS interrupt 0x15, function 0xE820
    mov edx,0x534d4150 ; 'SMAP' signature
    mov ecx,20 ; Size of the buffer for the memory map entry
    mov edi,0x9000 ; Address of the buffer to store the memory map entry
    xor ebx,ebx ; Set EBX to 0 for the first call
    int 0x15 ; Call BIOS interrupt to get memory map
    jc NotSupport ; Jump to NotSupport if the carry flag is set

GetMemInfo:
    add edi,20 ; Move to the next memory map entry
    mov eax,0xe820 ; Get memory map using BIOS interrupt 0x15, function 0xE820
    mov edx,0x534d4150 ; 'SMAP' signature
    mov ecx,20 ; Size of the buffer for the memory map entry
    int 0x15 ; Call BIOS interrupt to get memory map
    jc GetMemDone ; Jump to GetMemDone if the carry flag is set

    test ebx,ebx ; Check if there are more memory map entries
    jnz GetMemInfo ; Jump to GetMemInfo if there are more entries

GetMemDone:
TestA20:
    mov ax,0xffff ; Load 0xffff into AX for setting ES segment
    mov es,ax ; Set ES segment to 0xffff
    mov word[ds:0x7c00],0xa200 ; Write test value to memory
    cmp word[es:0x7c10],0xa200 ; Compare with the mirrored address in the high memory
    jne SetA20LineDone ; If not equal, A20 line is already enabled
    mov word[0x7c00],0xb200 ; Write another test value
    cmp word[es:0x7c10],0xb200 ; Compare with the mirrored address in the high memory
    je End ; If equal, jump to End
    

SetA20LineDone:
    xor ax,ax ; Clear AX register
    mov es,ax ; Set ES segment to 0x0000 after clearing AX

SetVideoMode:
    mov ax,3 ; Set video mode to 80x25 text mode
    int 0x10 ; Call BIOS interrupt to set video mode
    
    cli ; Clear interrupts before entering protected mode
    lgdt [Gdt32Ptr] ; Load the Global Descriptor Table for 32-bit protected mode
    lidt [Idt32Ptr] ; Load the Interrupt Descriptor Table for 32-bit protected mode

    mov eax,cr0 ; Load CR0 register
    or eax,1 ; Set the PE (Protection Enable) bit
    mov cr0,eax ; Store the updated value back to CR0

    jmp 8:PMEntry ; Far jump to the protected mode entry point

ReadError:
NotSupport:
End:
    hlt ; Halt the CPU
    jmp End ; Loop indefinitely after halting the CPU


[BITS 32]
PMEntry:
    mov ax,0x10 ; Load the data segment selector for protected mode
    mov ds,ax ; Set DS segment for protected mode
    mov es,ax ; Set ES segment for protected mode
    mov ss,ax ; Set SS segment for protected mode
    mov esp,0x7c00 ; Set stack pointer for protected mode

    cld ; Clear the direction flag for string operations
    mov edi,0x70000 ; Destination address for clearing memory
    xor eax,eax ; Clear EAX register to use as the value for stosd
    mov ecx,0x10000/4 ; Number of double words to clear
    rep stosd ; Clear memory by storing EAX into the destination repeatedly
    
    mov dword[0x70000],0x71007 ; Set up initial memory values
    mov dword[0x71000],10000111b ; Set up additional memory values


    lgdt [Gdt64Ptr] ; Load the Global Descriptor Table for 64-bit long mode

    mov eax,cr4 ; Load CR4 register
    or eax,(1<<5) ; Set the PAE (Physical Address Extension) bit
    mov cr4,eax ; Store the updated value back to CR4

    mov eax,0x70000 ; Load the base address of the page directory
    mov cr3,eax ; Store the page directory base address into CR3

    mov ecx,0xc0000080 ; Load the MSR address for enabling NX bit
    rdmsr ; Read the MSR into EDX:EAX
    or eax,(1<<8) ; Set the NXE (No-Execute Enable) bit
    wrmsr ; Write the updated value back to the MSR

    mov eax,cr0 ; Load CR0 register
    or eax,(1<<31) ; Set the PG (Paging) bit
    mov cr0,eax ; Store the updated value back to CR0

    jmp 8:LMEntry ; Far jump to the 64-bit long mode entry point

PEnd:
    hlt ; Halt the CPU
    jmp PEnd ; Loop indefinitely after halting the CPU

[BITS 64]
LMEntry:
    mov rsp,0x7c00 ; Set stack pointer for 64-bit long mode

    cld ; Clear the direction flag for string operations
    mov rdi,0x200000 ; Destination address for memory copy
    mov rsi,0x10000 ; Source address for memory copy
    mov rcx,51200/8 ; Number of quad words to copy
    rep movsq ; Copy memory from source to destination

    jmp 0x200000 ; Jump to the copied code in memory
    
LEnd:
    hlt ; Halt the CPU
    jmp LEnd ; Loop indefinitely after halting the CPU

DriveId:    db 0 ; Drive ID for the boot drive
ReadPacket: times 16 db 0 ; Buffer for reading disk packets

Gdt32:
    dq 0 ; Null descriptor for the GDT
Code32:
    dw 0xffff
    dw 0
    db 0
    db 0x9a
    db 0xcf
    db 0
Data32:
    dw 0xffff
    dw 0
    db 0
    db 0x92
    db 0xcf
    db 0
    
Gdt32Len: equ $-Gdt32

Gdt32Ptr: dw Gdt32Len-1
          dd Gdt32

Idt32Ptr: dw 0
          dd 0


Gdt64:
    dq 0
    dq 0x0020980000000000

Gdt64Len: equ $-Gdt64


Gdt64Ptr: dw Gdt64Len-1
          dd Gdt64