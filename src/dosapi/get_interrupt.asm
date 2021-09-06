segment .text

_get_interrupt:
    push bp
    mov bp, sp
    sub sp, 6
    pusha

    ; Save the old DS.
    mov [bp-2], ds

    ; ax = interrupt number.
    xor ah, ah

    ; Get the interrupt vector; multiple by two words.
    shl ax, 2

    ; Point DS:SI to the interrupt vector.
    ; Interrupt vector address = [0x0000:ah*4]
    mov si, ax
    xor ax, ax
    mov ds, ax

    ; Clear interrupts while changing interrupt vector.
    cli

    ; Get the interrupt's address.
    lodsw
    mov [bp-4], ax
    lodsw
    mov [bp-6], ax

    ; It's safe enough to restore interrupts.
    sti

.done:
    popa

    ; Restore old DS.
    mov ds, [bp-2]

    ; Return the interrupt's address in ES:BX.
    mov bx, [bp-4]
    mov es, [bp-6]

    mov sp, bp
    pop bp
    iret
