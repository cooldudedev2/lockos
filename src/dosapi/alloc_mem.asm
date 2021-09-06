segment .text

_alloc_mem:
    push bp
    mov bp, sp
    sub sp, 10
    pusha

    ; Save number of paragraphs to allocate.
    mov [bp-2], bx

    ; Save ES.
    mov [bp-4], es

    ; Save DS.
    mov [bp-6], ds

    ; Initialize the bitchain offset.
    mov word [bp-8], 0x0000

.reset:
    ; Set the counter to the requested paragraphs plus 1 for the MCB.
    mov cx, [bp-2]
    inc cx

.find_free:
    ; Not enough free space!
    cmp word [bp-8], 0x1000
    jae .fail

    ; Get the byte position in the bitchain.
    mov bx, [bp-8]
    shr bx, 0x0003
    mov al, [cs:bx+_dosapi_mem]

    ; Save the counter.
    push cx

    ; Get the bit position in the bitchain.
    mov cx, [bp-8]
    and cx, 0x0007
    shr al, cl

    ; Restore the counter.
    pop cx

    ; Increase offset.
    inc word [bp-8]

    ; Test to see if this bit is free.
    and al, 0x01
    jnz .reset

    loop .find_free

.next:
    ; Point the bitchain offset to the beginning of our chain.
    mov ax, [bp-8]
    sub ax, [bp-2]
    dec ax
    mov [bp-8], ax

    mov cx,[bp-2]
    inc cx

.fill_free:
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
    or al, dl

    ; Restore the counter.
    pop cx

    ; Update the byte in the bitchain.
    mov [cs:bx+_dosapi_mem], al

    ; Increase offset.
    inc word [bp-8]

    loop .fill_free

.mcb:
    ; Return the segment of the allocated memory.
    ; (1 paragraph from the start of allocated memory due to MCB.)
    mov ax, [cs:_dosapi_mem_seg]
    add ax, [bp-8]
    sub ax, [bp-2]

    ; Save the allocated memory segment.
    mov [bp-10], ax

    ; point to MCB.
    dec ax

    ; ES:DI points to MCB.
    mov es, ax
    xor di, di

    ; Last MCB paragraph in chain.
    mov al, 'z'
    stosb

    ; Default - the user program loaded it.
    mov ax, 0x08
    stosw

    ; Number of paragraphs allocated. (not including the MCB.)
    mov ax, [bp-2]
    stosw

    xor al, al
    mov cx, 19
    rep stosb

.success:
    ; Clear the caller's carry flag.
    and word [bp+6], 0xFFFE

    jmp .end

.fail:
    ; Set the caller's carry flag.
    or word [bp+6], 0x0001

.end:
    popa

    ; Return the segment of the allocated memory (1 paragraph above MCB.)
    mov ax, [bp-10]

    ; Restore ES.
    mov es, [bp-4]

    ; Restore DS.
    mov ds, [bp-6]

    mov sp, bp
    pop bp
    iret
