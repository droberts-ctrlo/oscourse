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
    lgdt [Gdt64Ptr]         ; Load the address of the GDT into the GDTR register

SetTss:
    mov rax,Tss             ; Load the address of the TSS into RAX register
    mov [TssDesc+2],ax      ; Set the low 16 bits of the TSS base address
    shr rax,16
    mov [TssDesc+4],al      ; Set the next 8 bits of the TSS base address
    shr rax,8
    mov [TssDesc+7],al      ; Set the next 8 bits of the TSS base address
    shr rax,8
    mov [TssDesc+8],eax     ; Set the high 32 bits of the TSS base address
    mov ax,0x20             ; Load the TSS selector into AX
    ltr ax                  ; Load the TSS into the task register

InitPIT:
    mov al,(1<<2)|(3<<4)    ; Set PIT control word for channel 2, mode 3, binary counting
    out 0x43,al             ; Send control word to PIT control port

    mov ax,11931
    out 0x40,al             ; Send low byte of divisor to PIT channel 0
    mov al,ah
    out 0x40,al             ; Send high byte of divisor to PIT channel 0

InitPIC:
    mov al,0x11             ; Start initialization sequence for PIC
    out 0x20,al             ; Send initialization command to master PIC
    out 0xa0,al             ; Send initialization command to slave PIC

    mov al,32
    out 0x21,al             ; Set vector offset for master PIC
    mov al,40
    out 0xa1,al             ; Set vector offset for slave PIC

    mov al,4
    out 0x21,al             ; Tell master PIC there is a slave PIC at IRQ2
    mov al,2
    out 0xa1,al             ; Tell slave PIC its cascade identity

    mov al,1
    out 0x21,al             ; Set master PIC to 8086/88 mode
    out 0xa1,al             ; Set slave PIC to 8086/88 mode

    mov al,11111110b
    out 0x21,al             ; Mask all interrupts on master PIC except IRQ0
    mov al,11111111b
    out 0xa1,al             ; Mask all interrupts on slave PIC

    push 8                  ; Push the code segment selector onto the stack
    push KernelEntry        ; Push the address of the kernel entry point onto the stack
    db 0x48                 ; Operand-size override prefix for the far return
    retf                    ; Far return to switch to the new code segment and jump to the kernel entry point

KernelEntry: 
    xor ax,ax               ; Clear AX register
    mov ss,ax               ; Set stack segment to 0
    
    mov rsp,0x200000        ; Set the stack pointer to 0x200000
    
    mov rsp,0x200000        ; Set the stack pointer to 0x200000 before calling the kernel main function
    call KMain              ; Call the kernel main function
    sti                     ; Enable interrupts

End:
    hlt                     ; Halt the CPU
    jmp End                 ; Infinite loop to keep the CPU halted
