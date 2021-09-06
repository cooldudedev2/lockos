segment .text

_buffer_stdin:
    push ds
    push es
    push bp
    mov bp, sp
    sub sp, 6

    pusha

    ; Save the buffer offset.
    mov [bp-2], dx

    ; Setup the keyboard buffer.
    mov di, dx
    mov dx, ds
    mov es, dx

    ; Save the max characters.
    mov cl, [es:di]

    ; Save the max character size.
    mov [bp-4], cl

    ; Make sure the max size is greater than 1!
    cmp cl, 0x01
    jb .done

    ; Point to the start of the buffer.
    add di, 2

    ; Save buffer start.
    mov [bp-6], di

.loop:
    ; Read for a keypress.
    xor ax, ax
    int 16h

    ; Add to the keyboard buffer.
    stosb

    ; Handle an enter key.
    cmp al, 0x0D
    je .enter

    ; Handle a backspace.
    cmp al, 0x08
    je .backspace

    ; Print the character to STDOUT.
    mov dl, al
    mov ah, 0x02
    int 0x21

    ; Keep looping unless the buffer is full!
    loop .loop
    jmp .done

.backspace:

    ; Go back one spot.
    dec di

    ; Make sure we can backspace!
    cmp di, [bp-6]
    jbe .loop

    dec di
    inc cl

    ; Do a backspace.
    mov dl, 0x08
    mov ah, 0x02
    int 0x21

    jmp .loop

.enter:
    ; Print carriage return.
    mov dl, 0x0D
    mov ah, 0x02
    int 0x21

    ; Print linefeed.
    mov dl, 0X0A
    mov ah, 0x02
    int 0x021

.done:
    ; Point to the buffers characters written field.
    mov di, [bp-2]
    inc di

    ; Update the buffer's charracters written field.
    mov al, byte [bp-4]
    sub al, cl
    stosb

    popa

    mov sp, bp
    pop bp
    pop es
    pop ds
    iret
