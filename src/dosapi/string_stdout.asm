segment .text

_string_stdout:
    push bp
    mov bp, sp
    pusha

    ; put the string output in SI.
    mov bx, dx

.loop:
    ; Load a character from the string.
    mov dl, byte [ds:bx]
    inc bx

    ; Exit if this is the end of the string.
    cmp dl, '$'
    je .done

    mov ah, 0x02
    int 0x21

    jmp .loop

.done:
    popa
    pop bp
    iret
