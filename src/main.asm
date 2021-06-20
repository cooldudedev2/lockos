_setup:

    ; Stop interrupts while changing the stack location to prevent corruption.
    cli

    ; Setup the stack.
    mov ax, 0x4000
    mov ss, ax
    xor ax, ax
    mov sp, ax

    ; It's safe to resume the interrupts.
    sti

    ; Setup the segment pointers
    mov ax, 0x3000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

_main:

    ; Idle loop.
    jmp $
