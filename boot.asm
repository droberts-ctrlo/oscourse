[BITS 16]
[ORG 0x7c00]

start:
    xor ax,ax               ; Clear AX register
    mov ds,ax               ; Set DS to 0
    mov es,ax               ; Set ES to 0
    mov ss,ax               ; Set SS to 0
    mov sp,0x7c00           ; Set stack pointer to 0x7c00

TestDiskExtension:
    mov [DriveId],dl        ; Store the drive ID in DriveId variable
    mov ah,0x41             ; Check for disk extension support
    mov bx,0x55aa           ; Set BX to the signature value
    int 0x13                ; Call BIOS disk service
    jc NotSupport           ; Jump if carry flag is set (error)
    cmp bx,0xaa55           ; Compare BX with expected signature
    jne NotSupport          ; Jump if not equal (extension not supported)

LoadLoader:
    mov si,ReadPacket       ; Load the address of the read packet into SI
    mov word[si],0x10       ; Set the size of the read packet
    mov word[si+2],5        ; Set the number of sectors to read
    mov word[si+4],0x7e00   ; Set the segment address for the buffer
    mov word[si+6],0        ; Set the offset address for the buffer
    mov dword[si+8],1       ; Set the starting LBA (Logical Block Address)
    mov dword[si+0xc],0     ; Reserved, set to 0
    mov dl,[DriveId]        ; Load the drive ID into DL register
    mov ah,0x42             ; Extended read sectors from drive
    int 0x13                ; Call BIOS disk service for extended read
    jc  ReadError           ; Jump if carry flag is set (read error)

    mov dl,[DriveId]
    jmp 0x7e00              ; Jump to the loaded loader code

ReadError:
NotSupport:
    mov ah,0x13             ; Teletype output function
    mov al,1                ; Number of characters to write
    mov bx,0xa              ; Page number and attribute
    xor dx,dx               ; Row and column
    mov bp,Message          ; Pointer to the message
    mov cx,MessageLen       ; Length of the message
    int 0x10                ; Call BIOS video service

End:
    hlt                     ; Halt the CPU
    jmp End                 ; Infinite loop to halt the system

DriveId:    db 0
Message:    db "We have an error in boot process"
MessageLen: equ $-Message
ReadPacket: times 16 db 0

; Partition table and boot signature follow
times (0x1be-($-$$)) db 0

    db 80h
    db 0,2,0
    db 0f0h
    db 0ffh,0ffh,0ffh
    dd 1
    dd (20*16*63-1)
	
    times (16*3) db 0

    db 0x55
    db 0xaa

	
