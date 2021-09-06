segment .text

_char_stdin:
    push bp
    mov bp, sp
    sub sp, 2

    pusha

    ; Clear out the state of the keypress variable.
    mov word [bp-2], 0

    ; Read for a keypress.
    xor ax, ax
    int 16h

    ; Save the keypress result.
    mov byte [bp-2], al

    mov dl, al
    mov ah, 0x02
    int 0x21

    popa

    ; Restore the keypress result.
    mov al, byte [bp-2]

    mov sp, bp
    pop bp
    iret
