segment .text

_free_mem:
    push bp
    mov bp, sp
    sub sp, 8
    pusha

    ; Save segments.
    mov [bp-2], es
    mov [bp-4], ds

    ; AX now holds number of paragraphs originally allocated.
    mov ax, es
    dec ax
    mov ds, ax
    mov si, 0x03
    lodsw
    mov [bp-6], ax

    ; Set the counter to size of paragraphs plus 1 for the MCB.
    mov cx, ax
    inc cx

    ; Get starting bit position.
    mov ax, [bp-2]
    sub ax, [cs:_dosapi_mem_seg]
    dec ax
    mov [bp-8], ax

.loop:

    ; Get the byte position in the bitchain.
    mov bx, [bp-8]
    shr bx, 0x0003
    mov al, [cs:bx+_dosapi_mem]

    ; Save the counter.
    push cx

    ; Mark the bit position as not free.
    mov cx, [bp-8]
    and cx, 0x0007
    mov dl, 0x01
    shl dl, cl
    not dl
    and al, dl

    ; Restore the counter.
    pop cx

    ; Update the byte in the bitchain.
    mov [cs:bx+_dosapi_mem], al

    ; Increase offset.
    inc word [bp-8]

    loop .loop

.success:
    ; Clear the caller's carry flag.
    and word [bp+6], 0xFFFE

    jmp .end

.fail:
    ; Set the caller's carry flag.
    or word [bp+6], 0x0001

.end:
    popa

    ; Restore ES.
    mov es, [bp-2]

    ; Restore DS.
    mov ds, [bp-4]

    mov sp, bp
    pop bp
    iret
