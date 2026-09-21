section .data

Gdt64:
    dq 0 ; Null descriptor for the GDT
    dq 0x0020980000000000 ; Code segment descriptor
    dq 0x0020f80000000000 ; Data segment descriptor
    dq 0x0000f20000000000 ; TSS descriptor (part 1)
TssDesc:
    dw TssLen-1 ; Limit of the TSS segment
    dw 0 ; Base address (low 16 bits) of the TSS segment
    db 0 ; Base address (next 8 bits) of the TSS segment
    db 0x89 ; Type and flags for the TSS segment
    db 0 ; Base address (next 8 bits) of the TSS segment
    db 0 ; Base address (next 8 bits) of the TSS segment
    dq 0 ; Base address (high 64 bits) of the TSS segment

Gdt64Len: equ $-Gdt64 ; Length of the GDT64

Gdt64Ptr: dw Gdt64Len-1 ; Pointer to the GDT64
          dq Gdt64 ; Address of the GDT64

Tss:
    dd 0 ; Reserved field for the TSS
    dq 0x190000 ; Base address of the TSS
    times 88 db 0 ; Reserved space for the TSS
    dd TssLen ; Limit of the TSS segment

TssLen: equ $-Tss ; Length of the TSS segment

section .text
extern KMain
global start

start:
    lgdt [Gdt64Ptr] ; Load the Global Descriptor Table for 64-bit long mode

SetTss:
    mov rax,Tss ; Load the base address of the TSS segment into RAX
    mov [TssDesc+2],ax ; Base address (low 16 bits) of the TSS segment
    shr rax,16
    mov [TssDesc+4],al ; Base address (next 8 bits) of the TSS segment
    shr rax,8
    mov [TssDesc+7],al ; Base address (next 8 bits) of the TSS segment
    shr rax,8
    mov [TssDesc+8],eax ; Base address (high 32 bits) of the TSS segment
    mov ax,0x20
    ltr ax ; Load the TSS segment selector into the task register

InitPIT:
    mov al,(1<<2)|(3<<4) ; Set PIT control word for mode 3, binary counting, and channel 0
    out 0x43,al ; Send the control word to the PIT control port

    mov ax,11931
    out 0x40,al ; Send the low byte of the divisor to the PIT channel 0 data port
    mov al,ah
    out 0x40,al ; Send the high byte of the divisor to the PIT channel 0 data port

InitPIC:
    mov al,0x11
    out 0x20,al ; Send the initialization command to the master PIC
    out 0xa0,al ; Send the initialization command to the slave PIC

    mov al,32
    out 0x21,al ; Set the vector offset for the master PIC
    mov al,40
    out 0xa1,al ; Set the vector offset for the slave PIC

    mov al,4
    out 0x21,al ; Tell the master PIC about the presence of the slave PIC
    mov al,2
    out 0xa1,al ; Tell the slave PIC its cascade identity

    mov al,1
    out 0x21,al ; Set the master PIC to 8086/88 mode
    out 0xa1,al ; Set the slave PIC to 8086/88 mode

    mov al,11111110b
    out 0x21,al ; Mask all interrupts on the master PIC except for the timer
    mov al,11111111b
    out 0xa1,al ; Mask all interrupts on the slave PIC

    push 8 ; Push the code segment selector for the kernel
    push KernelEntry ; Push the offset of the kernel entry point
    db 0x48 ; Operand-size override prefix for 64-bit mode
    retf ; Far return to switch to the kernel entry point in 64-bit mode

KernelEntry:
    mov rsp,0x200000 ; Set the stack pointer for the kernel
    call KMain ; Call the main kernel function

End: ; Kernel entry point exit label
    hlt ; Halt the CPU
    jmp End ; Infinite loop to prevent the CPU from executing unintended instructions


