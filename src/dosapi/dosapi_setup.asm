segment .text

_dosapi_setup:
    pusha

    ; Initialize the bss.
    mov di, _dosapi_bss_start
    mov cx, _dosapi_bss_end
    sub cx, _dosapi_bss_start
    xor al, al
    rep stosb

    ; Save the dosapi segment.
    mov [_dosapi_seg], cs
    mov word [_dosapi_mem_seg], 0x5000

    ; Point [GS:BX] to the int 0x21 entry in IVT.
    xor bx, bx
    mov gs, bx
    mov bx, 0x0084

    ; Set int 0x21 as [CS:_dosapi].
    mov ax, cs
    cli
    mov word [gs:bx], _dosapi
    mov [gs:bx+2], ax
    sti

    ; Initialize the disk.
    call _init_drive

    ; Restore all registers.
    popa

    ; Return 0
    xor ax, ax

    ret
