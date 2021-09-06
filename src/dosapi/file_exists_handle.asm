segment .text

_file_exists_handle:
    push bp
    mov bp, sp
    sub sp, 4
    pusha

    ; Save altered segments.
    mov [bp-2], ds
    mov [bp-4], es

    ; Load the root directory.
    push word [bp+4]
    call _load_root
    jc .fail
    add sp, 2

    ; Setup the segments for DI and SI.
    mov ds, [cs:_dosapi_seg]

    ; Get the file handle's FCB segment.
    mov bx, [bp+4]
    shl bx, 1
    add bx, _dosapi_files
    mov es, [bx]

    ; Load the file buffer.
    mov si, _dosapi_fb

    ; Setup a counter to loop through each directory entry.
    mov cx, [drive0.Dir_Entries]

    ; Added to the disk buffer to go the the next directory entry.
    ; Entry Size - SFN = file entry offset
    mov ax, 21

.loop:
    ; Save the loop counter.
    push cx

    ; Check the SFN for this entry and see if it's the file.
    mov di, FCB.filename
    mov cx, 11
    rep cmpsb
    je .success

    ; This isn't the file.
    ; Add the leftover offset (CX) to the file entry offset (AX).
    add cx, ax
    add si, cx

    ; Restore the loop counter.
    pop cx

    ; Loop if there's still unread directory entries.
    loop .loop

.fail:
    popa
    stc

    jmp .end

.success:
    pop cx
    popa
    clc

.end:

    ; Restore altered segments.
    mov ds, [bp-2]
    mov es, [bp-4]

    mov sp, bp
    pop bp
    ret
