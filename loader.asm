[BITS 16]
[ORG 0x7e00]

start:
    mov [DriveId],dl        ; Store the drive ID passed in DL into the DriveId variable 

    mov eax,0x80000000      ; Get the highest extended function supported by CPUID
    cpuid                   ; Call CPUID with EAX=0x80000000
    cmp eax,0x80000001      ; Check if the processor supports extended function 0x80000001
    jb NotSupport           ; Jump to NotSupport if not supported

    mov eax,0x80000001      ; Get extended processor info and feature bits
    cpuid
    test edx,(1<<29)        ; Check if the processor supports 64-bit mode
    jz NotSupport           ; Jump to NotSupport if not supported
    test edx,(1<<26)        ; Check if the processor supports SSE2
    jz NotSupport           ; Jump to NotSupport if not supported

LoadKernel:
    mov si,ReadPacket       ; Load the address of the read packet into SI register
    mov word[si],0x10       ; Set the size of the read packet structure
    mov word[si+2],100      ; Set the number of sectors to read
    mov word[si+4],0        ; Set the segment of the buffer
    mov word[si+6],0x1000   ; Set the offset of the buffer
    mov dword[si+8],6       ; Set the drive number
    mov dword[si+0xc],0     ; Reserved, must be zero
    mov dl,[DriveId]        ; Load the drive ID into DL register
    mov ah,0x42             ; BIOS extended read sectors function
    int 0x13                ; Call BIOS to read sectors
    jc  ReadError           ; Jump to ReadError if the read fails

GetMemInfoStart:
    mov eax,0xe820          ; Get system memory map
    mov edx,0x534d4150      ; 'SMAP' signature for the memory map
    mov ecx,20              ; Size of the memory map entry structure
    mov edi,0x9000          ; Address to store the memory map entries
    xor ebx,ebx             ; Clear EBX before calling the memory map function
    int 0x15                ; Call BIOS to get the memory map
    jc NotSupport           ; Jump to NotSupport if the call fails

GetMemInfo:
    add edi,20              ; Move to the next memory map entry
    mov eax,0xe820          ; Get system memory map
    mov edx,0x534d4150      ; 'SMAP' signature for the memory map
    mov ecx,20              ; Size of the memory map entry structure
    int 0x15                ; Call BIOS to get the next memory map entry
    jc GetMemDone           ; Jump to GetMemDone if the call fails

    test ebx,ebx            ; Check if there are more memory map entries
    jnz GetMemInfo          ; Jump to GetMemInfo if there are more memory map entries

GetMemDone:
TestA20:
    mov ax,0xffff                   ; Set ES segment to 0xffff
    mov es,ax
    mov word[ds:0x7c00],0xa200      ; Write test value to memory
    cmp word[es:0x7c10],0xa200      ; Compare with mirrored address
    jne SetA20LineDone              ; If not equal, A20 line is already enabled
    mov word[0x7c00],0xb200         ; Write another test value
    cmp word[es:0x7c10],0xb200      ; Compare with mirrored address
    je End                          ; If equal, jump to End
    

SetA20LineDone:
    xor ax,ax                        ; Clear AX register
    mov es,ax                        ; Set ES segment to 0x0000

SetVideoMode:
    mov ax,3                ; Set video mode to 80x25 text mode
    int 0x10                ; Call BIOS to set the video mode
    
    cli                     ; Clear interrupts before entering protected mode
    lgdt [Gdt32Ptr]         ; Load the Global Descriptor Table for 32-bit mode
    lidt [Idt32Ptr]         ; Load the Interrupt Descriptor Table for 32-bit mode

    mov eax,cr0
    or eax,1                ; Set the PE (Protection Enable) bit in CR0
    mov cr0,eax

    jmp 8:PMEntry           ; Jump to the protected mode entry point

ReadError:
NotSupport:
End:
    hlt                     ; Halt the CPU
    jmp End                 ; Loop indefinitely after halting the CPU


[BITS 32]
PMEntry:
    mov ax,0x10             ; Set data segment selector for protected mode
    mov ds,ax               ; Set DS segment for protected mode
    mov es,ax               ; Set ES segment for protected mode
    mov ss,ax               ; Set SS segment for protected mode
    mov esp,0x7c00          ; Set the stack pointer for protected mode

    cld                     ; Clear the direction flag for string operations
    mov edi,0x70000         ; Destination address for memory initialization
    xor eax,eax             ; Clear EAX register
    mov ecx,0x10000/4       ; Number of double words to initialize
    rep stosd               ; Initialize memory with zeros
    
    mov dword[0x70000],0x71007       ; Set up initial memory values
    mov dword[0x71000],10000111b     ; Set up initial memory values


    lgdt [Gdt64Ptr]           ; Load the Global Descriptor Table for 64-bit mode

    mov eax,cr4               ; Read CR4 register
    or eax,(1<<5)             ; Set the PAE (Physical Address Extension) bit in CR4
    mov cr4,eax               ; Write back to CR4 register

    mov eax,0x70000           ; Set the base address for the page directory
    mov cr3,eax               ; Load the page directory base into CR3

    mov ecx,0xc0000080        ; Select the IA32_EFER MSR
    rdmsr                     ; Read the MSR into EDX:EAX
    or eax,(1<<8)             ; Set the LME (Long Mode Enable) bit
    wrmsr                     ; Write back to the MSR

    mov eax,cr0               ; Read CR0 register
    or eax,(1<<31)            ; Set the PG (Paging) bit to enable paging
    mov cr0,eax               ; Write back to CR0 register

    jmp 8:LMEntry             ; Jump to the long mode entry point

PEnd:                         ; Halt the CPU
    jmp PEnd                  ; Loop indefinitely after halting the CPU

[BITS 64]
LMEntry:
    mov rsp,0x7c00              ; Set the stack pointer for long mode

    cld                         ; Clear the direction flag for string operations
    mov rdi,0x200000            ; Destination address for memory copy
    mov rsi,0x10000             ; Source address for memory copy
    mov rcx,51200/8             ; Number of quad words to copy
    rep movsq                   ; Copy memory from source to destination

    jmp 0x200000                ; Jump to the copied memory location
    
LEnd:
    hlt                         ; Halt the CPU
    jmp LEnd                    ; Loop indefinitely after halting the CPU

DriveId:    db 0
ReadPacket: times 16 db 0

Gdt32:
    dq 0
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
