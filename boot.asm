[BITS 16]
[ORG 0x7c00]

start:
    xor ax,ax   ; Clear AX register
    mov ds,ax   ; Set DS to 0
    mov es,ax   ; Set ES to 0
    mov ss,ax   ; Set SS to 0
    mov sp,0x7c00  ; Set stack pointer to 0x7c00

TestDiskExtension:
    mov [DriveId],dl ; Store the drive ID in the DriveId variable
    mov ah,0x41   ; Check for disk extension support
    mov bx,0x55aa   ; Set BX to the signature value
    int 0x13        ; Call BIOS interrupt
    jc NotSupport   ; Jump if carry flag is set (error)
    cmp bx,0xaa55   ; Check if BX contains the expected signature
    jne NotSupport  ; Jump if not supported

LoadLoader:       ; Load the second stage loader into memory
    mov si,ReadPacket       ; Set SI to point to the read packet
    mov word[si],0x10       ; Set the size of the read packet
    mov word[si+2],5        ; Set the number of sectors to read
    mov word[si+4],0x7e00   ; Set the segment address to load the loader
    mov word[si+6],0        ; Set the offset address to load the loader
    mov dword[si+8],1       ; Set the starting LBA sector
    mov dword[si+0xc],0     ; Reserved
    mov dl,[DriveId]         ; Set the drive ID
    mov ah,0x42              ; BIOS extended read function
    int 0x13                 ; Call BIOS interrupt
    jc  ReadError            ; Jump if read error occurs

    mov dl,[DriveId]
    jmp 0x7e00   ; Jump to the loaded second stage loader

ReadError:
NotSupport:
    mov ah,0x13         ; BIOS teletype output function
    mov al,1            ; Number of characters to write
    mov bx,0xa          ; Page number and attribute
    xor dx,dx           ; Row and column
    mov bp,Message      ; Pointer to the message
    mov cx,MessageLen   ; Length of the message
    int 0x10            ; Call BIOS interrupt to display the message

End:
    hlt         ; Halt the CPU
    jmp End     ; infinite loop to halt the system
    
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
