segment .text

_set_interrupt:
    push bp
    mov bp, sp
    sub sp, 2
    pusha

    ; Save the old ES.
    mov [bp-2], es

    ; ax = interrupt number.
    xor ah, ah

    ; Get the interrupt vector; multiple by two words.
    shl ax, 2

    ; Point ES:DI to the interrupt vector.
    ; Interrupt vector address = [0x0000:ah*4]
    mov di, ax
    xor ax, ax
    mov es, ax

    ; Clear interrupts while changing interrupt vector.
    cli

    ; Update the interrupt's address.
    mov ax, dx
    stosw
    mov ax, ds
    stosw

    ; It's safe enough to restore interrupts.
    sti

.done:
    ; Restore old ES.
    mov es, [bp-2]

    popa
    mov sp, bp
    pop bp
    iret
