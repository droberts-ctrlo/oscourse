[BITS 16]
[ORG 0x7e00]

start:
    mov [DriveId],dl        ; Store the drive ID passed in DL into DriveId variable

    mov eax,0x80000000      ; Get the highest extended function supported by CPUID
    cpuid                   ; Call CPUID with EAX=0x80000000
    cmp eax,0x80000001      ; Check if extended function 0x80000001 is supported
    jb NotSupport           ; Jump if not supported

    mov eax,0x80000001      ; Get extended function 0x80000001
    cpuid                   ; Call CPUID with EAX=0x80000001
    test edx,(1<<29)        ; Check if the 64-bit feature is supported
    jz NotSupport           ; Jump if not supported
    test edx,(1<<26)        ; Check if the SSE2 feature is supported
    jz NotSupport           ; Jump if not supported

LoadKernel:
    mov si,ReadPacket       ; Load the address of the read packet structure into SI
    mov word[si],0x10       ; Set the size of the read packet structure
    mov word[si+2],100      ; Set the number of sectors to read
    mov word[si+4],0        ; Set the segment of the buffer
    mov word[si+6],0x1000   ; Set the offset of the buffer
    mov dword[si+8],6       ; Set the LBA of the first sector to read
    mov dword[si+0xc],0     ; Reserved, must be zero
    mov dl,[DriveId]        ; Load the drive ID into DL for the BIOS read call
    mov ah,0x42             ; BIOS read sectors function
    int 0x13                ; Call BIOS interrupt 0x13
    jc  ReadError           ; Jump if carry flag is set (read error)

GetMemInfoStart:
    mov eax,0xe820          ; Get system memory map
    mov edx,0x534d4150      ; 'SMAP' signature for the memory map
    mov ecx,20              ; Size of the memory map entry structure
    mov edi,0x9000          ; Address to store the memory map entry
    xor ebx,ebx             ; Continuation value, set to 0 for the first call
    int 0x15                ; Call BIOS interrupt 0x15 to get the memory map
    jc NotSupport           ; Jump if carry flag is set (not supported)

GetMemInfo:
    add edi,20              ; Move to the next memory map entry
    mov eax,0xe820          ; Get system memory map
    mov edx,0x534d4150      ; 'SMAP' signature for the memory map
    mov ecx,20              ; Size of the memory map entry structure
    int 0x15                ; Call BIOS interrupt 0x15 to get the memory map
    jc GetMemDone           ; Jump if carry flag is set (no more entries or error)

    test ebx,ebx            ; Check if there are more memory map entries
    jnz GetMemInfo          ; Jump to get the next memory map entry if EBX is not zero

GetMemDone:
TestA20:
    mov ax,0xffff                    ; Load 0xffff into AX for A20 line test
    mov es,ax                        ; Set ES to 0xffff for A20 line test
    mov word[ds:0x7c00],0xa200       ; Write test value to memory for A20 line test
    cmp word[es:0x7c10],0xa200       ; Compare with the mirrored address
    jne SetA20LineDone               ; If not equal, A20 line is already enabled
    mov word[ds:0x7c00],0xb200       ; Write another test value
    cmp word[es:0x7c10],0xb200       ; Compare with the mirrored address
    je End                           ; If equal, A20 line is not enabled, halt
    

SetA20LineDone:
    xor ax,ax                        ; Clear AX
    mov es,ax                        ; Set ES to 0 for A20 line test completion

SetVideoMode:
    mov ax,3                        ; Set video mode to 80x25 text mode
    int 0x10                        ; Call BIOS interrupt 0x10 to set video mode
    
    cli                             ; Clear interrupt flag to disable interrupts before entering protected mode
    lgdt [Gdt32Ptr]                 ; Load the Global Descriptor Table for 32-bit protected mode
    lidt [Idt32Ptr]                 ; Load the Interrupt Descriptor Table for 32-bit protected mode

    mov eax,cr0                     ; Get the current value of CR0
    or eax,1                        ; Set the PE (Protection Enable) bit
    mov cr0,eax                     ; Update CR0 to enable protected mode

    jmp 8:PMEntry                   ; Far jump to the 32-bit protected mode entry point

ReadError:
NotSupport:
End:
    hlt                             ; Halt the CPU
    jmp End                         ; Infinite loop to halt the CPU


[BITS 32]
PMEntry:
    mov ax,0x10                     ; Set data segment selector for protected mode
    mov ds,ax                       ; Set DS to the data segment selector
    mov es,ax                       ; Set ES to the data segment selector
    mov ss,ax                       ; Set SS to the data segment selector
    mov esp,0x7c00                  ; Initialize the stack pointer

    cld                             ; Clear the direction flag for string operations
    mov edi,0x70000                 ; Destination address for memory initialization
    xor eax,eax                     ; Clear EAX to use as the value for initialization
    mov ecx,0x10000/4               ; Number of double words to initialize
    rep stosd                       ; Initialize memory with zeros
    
    mov dword[0x70000],0x71007      ; Set up the first memory location with a specific value
    mov dword[0x71000],10000111b    ; Set up the second memory location with a specific value


    lgdt [Gdt64Ptr]                 ; Load the Global Descriptor Table for 64-bit long mode 

    mov eax,cr4                     ; Get the current value of CR4
    or eax,(1<<5)                   ; Set the PAE (Physical Address Extension) bit
    mov cr4,eax                     ; Update CR4 to enable PAE

    mov eax,0x70000                  ; Set the base address of the page directory
    mov cr3,eax                      ; Load the page directory base into CR3

    mov ecx,0xc0000080               ; IA32_EFER MSR
    rdmsr                            ; Read the MSR into EDX:EAX
    or eax,(1<<8)                    ; Set the LME (Long Mode Enable) bit
    wrmsr                            ; Write the updated value back to the MSR

    mov eax,cr0                     ; Get the current value of CR0
    or eax,(1<<31)                  ; Set the PG (Paging) bit to enable paging
    mov cr0,eax                     ; Update CR0 to enable paging

    jmp 8:LMEntry                   ; Jump to the 64-bit long mode entry point

PEnd:
    hlt                             ; Halt the CPU
    jmp PEnd                        ; Infinite loop to halt the CPU

[BITS 64]
LMEntry:
    mov rsp,0x7c00                  ; Initialize the stack pointer for 64-bit long mode

    cld                             ; Clear the direction flag for string operations
    mov rdi,0x200000                ; Destination address for memory copy
    mov rsi,0x10000                 ; Source address for memory copy
    mov rcx,51200/8                 ; Number of quad words to copy
    rep movsq                       ; Copy memory from source to destination

    jmp 0x200000                    ; Jump to the copied memory location in 64-bit long mode
    
LEnd:
    hlt                             ; Halt the CPU
    jmp LEnd                        ; Infinite loop to halt the CPU
    
    

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
