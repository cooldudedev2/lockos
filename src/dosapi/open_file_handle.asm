segment .text

_open_file_handle:
    push bp
    mov bp, sp
    sub sp, 16
    pusha

    ; Save the buffer.
    mov [bp-14], dx

    ; Save the access flag.
    mov [bp-12], al

    ; Update the segments.
    mov [bp-4], ds
    mov [bp-8], es
    mov [bp-10], gs
    mov dx, cs
    mov ds, dx
    mov es, dx

    ; Reset the counter.
    xor cx, cx
    dec cx
    mov si, _dosapi_files

.find_free_handle:
    ; Increase the counter.
    inc cx

    ; Are we done?
    cmp cx, 0x00FF
    jae .fail_04

    ; Check to see if the file handle pointer is null. [segment:offset]
    lodsw
    cmp ax, 0x0000
    jnz .find_free_handle

    ; Save the file handle.
    mov [bp-2], cx

.alloc_fh:
    ; Get the number of paragraphs need to allocate a FCB.
    ; paragraphs to allocate = (FCB bytes / 16) + 1
    mov bx, FCB.size
    shr bx, 0x04
    inc bx
    mov ah, 0x48
    int 0x21
    jc .fail_08

    ; Save the memory pointer.
    mov [bp-6], ax

    ; Setup the file handle pointer.
    mov di, [bp-2]
    shl di, 1
    add di, _dosapi_files

    ; Save the pointer.
    stosw

    ; Clean up allocated memory.
    mov es, [bp-6]
    mov cx, FCB.size
    mov di, FCB
    xor al, al
    rep stosb

    ; Initial data.
    mov al, [bp-12]
    mov [es:FCB.access], al
    mov byte [es:FCB.drive], 0x00
    mov word [es:FCB.pointer], 0x0000

    ; Load the pointer.
    mov si, [bp-14]

    ; Clear the counter.
    xor cx, cx

    ; Point DS:SI to the file path.
    mov ds, [bp-4]

.path_size:

    ; Check the size of the file path.
    lodsb
    inc cx
    cmp al, 0x00
    jne .path_size

    ; Make sure the file path buffer doesn't overflow.
    cmp cx, 0x20
    ja .fail_08

    ; Copy filepath.
    mov si, [bp-14]
    mov di, FCB.path
    rep movsb

    ; Get ready to copy the file path into a SFN.
    mov ds, [bp-6]
    mov si, FCB.path
    mov di, FCB.filename
    mov cx, 8

.get_file:
    lodsb

    cmp al, 0x00
    je .done_early

    cmp al, '.'
    je .finish_file

    ; Max size 8.
    cmp cx, 0
    je .fail_08

    dec cx

    ; Convert to uppercase, if neccessary.
    cmp al, 0x61
    jb .next_file

    cmp al, 0x7A
    ja .next_file

    sub al, 0x20

.next_file:
    stosb

    jmp .get_file

.finish_file:

    ; Pad with spaces.
    mov al, ' '
    rep stosb

    mov di, FCB.extname
    mov cx, 3

.get_ext:
    lodsb

    cmp al, 0x00
    je .done

    ; Max size 3.
    cmp cx, 0
    je .fail_08

    dec cx

    ; Convert to uppercase, if neccessary.
    cmp al, 0x61
    jb .next_ext

    cmp al, 0x7A
    ja .next_ext

    sub al, 0x20

.next_ext:
    stosb

    jmp .get_ext

.done_early:
    add cx, 3

.done:
    ; Padd with spaces.
    mov al, ' '
    rep stosb

    ; Make sure the file exists!
    push word [bp-2]
    call _file_exists_handle
    jc .clean_fail
    add sp, 2

    ; Load the file buffer.
    mov ds, [cs:_dosapi_seg]
    mov si, _dosapi_fb

    ; Setup a counter to loop through each directory entry.
    mov cx, [cs:drive0.Dir_Entries]

    ; Added to the disk buffer to go the the next directory entry.
    ; Entry Size - SFN = file entry offset
    mov ax, 21

.find_file:
    ; Save the loop counter.
    push cx

    ; Check the SFN for this entry and see if it's the file.
    mov di, FCB.filename
    mov cx, 0x0B
    rep cmpsb
    je .read_file

    ; This isn't the file.
    ; Add the leftover offset (CX) to the file entry offset (AX).
    add cx, ax
    add si, cx

    ; Restore the loop counter.
    pop cx

    ; Loop if there's still unread directory entries.
    loop .find_file

    jmp .fail_02

.read_file:
    pop cx

    ; Copy file information into our file struct.
    mov di, FCB.attr
    mov cx, 0x15
    rep movsb

    ; Load the disk's FAT into the disk buffer.
    push word [bp-2]
    call _load_fat
    jc .clean_fail

    ; Clean up the stack.
    add sp, 2

    ; Setup the cluster chain and copy the initial cluster.
    mov di, FCB.cluster_chain
    mov ax, [es:FCB.low_cluster]
    stosw

.next_cluster:

    ; cluster offset = cluster * 1.5
    mov dx, ax
    shr dx, 1
    add ax, dx

    ; Point to the next cluster in the FAT.
    mov si, _dosapi_fb
    add si, ax

    ; Get our next cluster from the FAT.
    lodsw

    ; Check to see if the original cluster was odd or even.
    mov dx, [es:di-2]
    and dx, 0x0001
    jz .even_cluster

.odd_cluster:
    ; The original cluster was odd so we need to remove the lowest nibble.
    shr ax, 4
    jmp .check_cluster

.even_cluster:
    ; The original cluster was even so we need to remove the highest nibble.
    and ax, 0x0FFF

; Check to see if the cluster chain still needs to continue.
.check_cluster:

    stosw

    ; Check to see if this cluster is bad.
    cmp ax, 0x0FF7
    je .fail_0D

    ; Check to see if this is the end of the cluster chain.
    cmp ax, 0x0FF8
    jb .next_cluster

    ; Set the counter.
    xor cx, cx
    dec cx
    mov [bp-16], cx

.check_file_handle:
    ; Increase the counter.
    inc word [bp-16]

    mov cx, [bp-16]

    ; Check the counter.
    cmp cx, 0x00FF
    jae .success

    ; Don't check the new file handle.
    cmp cx, [bp-2]
    je .check_file_handle

    ; DS:SI points to file handle pointer.
    mov ds, [cs:_dosapi_seg]
    mov si, _dosapi_files
    shl cx, 0x01
    add si, cx
    lodsw

    ; Check to see if this is an valid file handle.
    cmp ax, 0x0000
    je .check_file_handle

    ; Compare the new file handle's name against this file handle's name.
    mov ds, ax
    mov si, FCB.filename
    mov di, FCB.filename
    mov cx, 0x0A
    repe cmpsb
    jne .check_file_handle

    ; If this file handle isn't valid, close it and fail.
    ; FIX: Close file handle.
    jmp .fail_05

.success:
    ; Clear the caller's carry flag.
    and word [bp+6], 0xFFFE

    jmp .end

.fail_02:
    ; File not found.
    mov ax, 0x0002
    jmp .fail

.fail_04:
    ; Too many open file handles.
    mov ax, 0x0004
    jmp .fail


.fail_05:
    ; Insufficient memory.
    mov ax, 0x0005
    jmp .fail


.fail_08:
    ; Insufficient memory.
    mov ax, 0x0008
    jmp .fail

.fail_0D:
    ; Invalid data.
    mov ax, 0x000D
    jmp .fail

.clean_fail:

    ; Clean up the stack.
    add sp, 2
    mov ax, 0x000E

.fail:
    ; Return the error code, not file handle.
    mov [bp-2], ax

    ; Set the caller's carry flag.
    or word [bp+6], 0x0001

.end:
    popa

    ; Return the file handle.
    mov ax, [bp-2]

    mov ds, [bp-4]
    mov es, [bp-8]
    mov gs, [bp-10]
    mov sp, bp
    pop bp

    iret

segment .bss

; FCB used by both handle and FCB functions.
struc FCB
.pointer: resw 0x01
.access: resb 0x01
.drive: resb 0x01
.path: resb 0x20

; FAT entry information.
.filename: resb 0x08
.extname: resb 0x03
.attr: resb 0x01
.nt_res: resb 0x01
.create_tenth: resb 0x01
.create_time: resw 0x01
.create_date: resw 0x01
.access_date: resw 0x01
.high_cluster: resw 0x01
.mod_time: resw 0x01
.mod_date: resw 0x01
.low_cluster: resw 0x01
.file_size: resd 0x01

; Big enough for an 64 KiB and an ending cluster
; NOTE: Includes the first cluster is stored in [.high_cluster]:[.low_cluster]
.cluster_chain: resw 0x81

; Size of the FCB structure in bytes. Used for malloc.
.size:
endstruc
