section .data

Gdt64:
    dq 0
    dq 0x0020980000000000
    dq 0x0020f80000000000
    dq 0x0000f20000000000
TssDesc:
    dw TssLen-1
    dw 0
    db 0
    db 0x89
    db 0
    db 0
    dq 0

Gdt64Len: equ $-Gdt64

Gdt64Ptr: dw Gdt64Len-1
          dq Gdt64

Tss:
    dd 0
    dq 0x190000
    times 88 db 0
    dd TssLen

TssLen: equ $-Tss

section .text
extern KMain
global start

start:
    lgdt [Gdt64Ptr] ; Load the address of the GDT into the GDTR register

SetTss:
    mov rax,Tss         ; Load the address of the TSS into RAX
    mov [TssDesc+2],ax  ; Set the low 16 bits of the TSS base address
    shr rax,16
    mov [TssDesc+4],al  ; Set the next 8 bits of the TSS base address
    shr rax,8
    mov [TssDesc+7],al  ; Set the next 8 bits of the TSS base address
    shr rax,8
    mov [TssDesc+8],eax ; Set the high 32 bits of the TSS base address
    mov ax,0x20         ; Load the TSS selector into AX
    ltr ax              ; Load the TSS into the task register

InitPIT:
    mov al,(1<<2)|(3<<4)   ; Set PIT mode and access mode
    out 0x43,al            ; Send command to PIT control port

    mov ax,11931           ; Set PIT frequency divisor
    out 0x40,al            ; Send low byte to PIT channel 0
    mov al,ah
    out 0x40,al            ; Send high byte to PIT channel 0

InitPIC:
    mov al,0x11            ; Initialize PIC (ICW1)
    out 0x20,al            ; Send ICW1 to master PIC
    out 0xa0,al            ; Send ICW1 to slave PIC

    mov al,32
    out 0x21,al            ; Send ICW2 to master PIC (vector offset)
    mov al,40
    out 0xa1,al            ; Send ICW2 to slave PIC (vector offset)

    mov al,4
    out 0x21,al            ; Send ICW3 to master PIC (cascade)
    mov al,2
    out 0xa1,al            ; Send ICW3 to slave PIC (cascade)

    mov al,1
    out 0x21,al            ; Send ICW4 to master PIC
    out 0xa1,al            ; Send ICW4 to slave PIC

    mov al,11111110b
    out 0x21,al            ; Set master PIC mask
    mov al,11111111b
    out 0xa1,al            ; Set slave PIC mask

    push 8                 ; Push the code segment selector
    push KernelEntry       ; Push the offset of the kernel entry point
    db 0x48                ; Operand-size override prefix for 64-bit
    retf                   ; Far return to switch to 64-bit code segment

KernelEntry:
    mov rsp,0x200000       ; Set the stack pointer for the kernel
    call KMain             ; Call the kernel main function

End:                     ; Kernel end loop
    hlt                  ; Halt the CPU
    jmp End              ; Infinite loop to keep the kernel running
