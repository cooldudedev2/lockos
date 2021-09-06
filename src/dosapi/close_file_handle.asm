segment .text

_close_file_handle:
    push bp
    mov bp, sp
    sub sp, 8
    pusha


    ; Save the file handle.
    mov [bp-2], bx

    ; Save the segments.
    mov [bp-4], ds
    mov [bp-6], es

    ; DS:SI points to file handle pointer.
    mov ds, [cs:_dosapi_seg]
    mov si, _dosapi_files
    mov cx, bx
    shl cx, 0x01
    add si, cx
    mov [bp-8], si ; Save the file handle pointer location.
    lodsw

    ; Is this a valid file handle?
    cmp ax, 0x0000
    je .fail

    ; Free the memory for the FCB.
    mov es, ax
    mov ah, 0x49
    int 0x21
    jc .fail

    ; Null the pointer.
    xor ax, ax
    mov di, [bp-8]
    stosw

.success:
    ; Clear the caller's carry flag.
    and word [bp+6], 0xFFFE

    jmp .end

.fail:
    ; Set the caller's carry flag.
    or word [bp+6], 0x0001

.end:
    popa

    mov ds, [bp-4]
    mov es, [bp-6]
    mov sp, bp
    pop bp

    iret
