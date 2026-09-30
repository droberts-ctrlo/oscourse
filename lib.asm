section .text
global memset
global memmove
global memcpy
global memcmp

memset:
    cld                 ; Clear direction flag to ensure forward string operations
    mov ecx, edx        ; Set the counter to the size of the buffer
    mov al, sil         ; Set the value to fill
    rep stosb           ; Fill the buffer with the value
    ret

memcmp:
    cld                 ; Clear direction flag to ensure forward string operations
    xor eax,eax         ; Clear the result register
    mov ecx, edx        ; Set the counter to the size of the buffers
    repe cmpsb          ; Compare the buffers byte by byte
    setnz al            ; Set AL to 1 if the buffers are not equal, 0 otherwise
    ret

memcpy:
memmove:
    cld                 ; Clear direction flag to ensure forward string operations
    cmp rsi,rdi         ; Compare source and destination addresses
    jae .copy           ; If source is above or equal to destination, copy forward
    mov r8,rsi          ; Save the source address
    add r8,rdx          ; Move the saved source address to the end of the buffer
    cmp r8,rdi          ; Compare the end of the source buffer with the destination address
    jbe .copy           ; If the end of the source buffer is below or equal to the destination, copy forward

.overlap:
    std                 ; Set direction flag to ensure backward string operations
    add rdi, rdx        ; Move the destination pointer to the end of the buffer for backward copy
    add rsi, rdx        ; Move the source pointer to the end of the buffer for backward copy
    sub rdi, 1          ; Adjust the destination pointer for backward copy
    sub rsi, 1          ; Adjust the source pointer for backward copy

.copy:
    mov ecx,edx         ; Set the counter to the size of the buffer
    rep movsb           ; Copy the buffer byte by byte
    cld                 ; Clear direction flag to restore default string operation direction
    ret
