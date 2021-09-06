segment .text

; Loads drive0's root directory into the dosapi file buffer.
_load_root:
    push bp
    mov bp, sp
    sub sp, 4
    pusha

    ; Save altered segments.
    mov [bp-2], ds
    mov [bp-4], es

    ; Set the data segment.
    mov ds, [cs:_dosapi_seg]

    ; Convert Root Directory LBA to CHS.
    mov ax, [cs:drive0.root_dir]
    call _lba_to_chs

    ; Get the file handle's FCB segment.
    mov bx, [bp+4]
    shl bx, 1
    add bx, _dosapi_files
    mov es, [bx]

    ; Load the Root Directory into the disk buffer.
    stc
    mov ax, [cs:drive0.root_dir_sectors]
    mov ah, 0x02
    mov dl, [es:FCB.drive]
    mov bx, [cs:_dosapi_seg]
    mov es, bx
    mov bx, _dosapi_fb
    int 0x13

    jc .fail

    popa
    clc

    jmp .end

.fail:
    popa
    stc

.end:
    ; Restore altered segments.
    mov ds, [bp-2]
    mov es, [bp-4]

    mov sp, bp
    pop bp
    ret
