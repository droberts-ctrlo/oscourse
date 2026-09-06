[BITS 16]
[ORG 0x7e00]

start:
    mov ah,0x13
    mov al,1
    mov bx,0xa
    xor dx,dx
    mov bp,Message
    mov cx,MessageLength
    int 0x10
    jmp End

End:
    hlt
    jmp End

Message db 'Welcome to Orion'
MessageLength equ $ - Message

