[BITS 16]
[ORG 0x7e00]

start:
    mov ah,0x13 ; BIOS teletype output function
    mov al,1 ; Number of characters to write
    mov bx,0xa ; Page number and attribute
    xor dx,dx ; Row and column
    mov bp,Message ; Pointer to the message
    mov cx,MessageLength ; Length of the message
    int 0x10 ; Call BIOS to display the message
    jmp End

End:
    hlt ; Halt the CPU
    jmp End ; Loop indefinitely after halting the CPU

Message db 'Welcome to Orion' ; Message to display
MessageLength equ $ - Message ; Length of the message

