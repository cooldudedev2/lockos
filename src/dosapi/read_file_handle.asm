segment .text

_read_file_handle:
    push bp
    mov bp, sp
    sub sp, 24
    pusha


    ; Define a list of local variables allocated on the stack.
    ; IN
    %define .bytes_to_read bp-2
    %define .file_handle bp-4
    %define .buffer_segment bp-6
    %define .buffer_offset bp-8

    ; LOCAL
    %define .bytes_per_cluster bp-10
    %define .bytes_read bp-12
    %define .FCB_segment bp-14
    %define .start_cluster bp-16
    %define .pointer_offset bp-18
    %define .cluster_chain_offset bp-20

    ; Old segment. (Doesn't include .buffer_segment, which is old DS.)
    %define .old_es bp-22
    %define .old_gs bp-24

    mov word [.bytes_read], 0x0000

    ; Is there anything to read?
    cmp cx, 0
    je .success

    mov [.bytes_to_read], cx                ; Save the number of bytes to read.
    mov [.buffer_offset], dx                ; Save the buffer offset.
    mov word [.start_cluster], 0x0000       ; Starting cluster.
    mov word [.pointer_offset], 0x0000      ; Pointer offset.
    mov word [.bytes_per_cluster], 0x0000   ; Bytes_Per_Cluster
    mov word [.buffer_segment], ds          ; Save the buffer segment.
    mov [.file_handle], bx                  ; Save the file handle to read.
    mov [.old_es], es                       ; Save old ES.
    mov [.old_gs], gs                       ; Save old GS.


    ; Setup the data segment.
    mov ds, [cs:_dosapi_seg]

    ; Get the file handle's FCB segment.
    shl bx, 1
    add bx, _dosapi_files
    mov ax, [bx]

    ; Make sure this is a valid file handle.
    cmp ax, 0x0000
    je .fail

    ; Save the FCB segment.
    mov [.FCB_segment], ax

    ; Setup the FCB segment.
    mov gs, ax

    ; Is the file pointer past EOF?
    mov cx, [gs:FCB.pointer]
    cmp cx, [gs:FCB.file_size]
    jae .success

    ; Get the number of bytes per cluster.
    mov ax, [cs:drive0.Sectors_Per_Cluster]
    mul word [cs:drive0.Bytes_Per_Sector]
    mov [.bytes_per_cluster], ax

.get_cluster:
    ; Find the first cluster to load and the pointer offset.
    xor dx, dx
    mov ax, [gs:FCB.pointer]
    div word [.bytes_per_cluster]
    mov [.start_cluster], ax
    mov [.pointer_offset], dx

    ; Multiple cluster start by 2 because each array element is a word in size.
    shl ax, 0x0001

    ; Setup the cluster_chain pointer.
    mov si, FCB.cluster_chain
    add si, ax

    ; Load the FCB segment.
    mov es, [.FCB_segment]
    mov ds, [.FCB_segment]

    ; Load the next cluster.
    lodsw

.load_cluster:
    ; Get the cluster offset so it can be read from the FAT.
    ; Cluster Offset = (Cluster-2) * Sectors_Per_Cluster.
    sub ax, 2
    xor dh, dh
    mov dl, [cs:drive0.Sectors_Per_Cluster]
    mul dx

    ; Save the Cluster Offset.
    push ax

    ; Get the starting data sector of the cluster.
    ; First Cluster Sector = Root Directory Start + Root Directory Sectors
    ;                        + Cluster Offset

    ; Calculate the start of the Root Directory.
    ; Root Directory Start = (Sectors_Per_FAT * FATs) + Reserved_Sectors
    xor dx, dx
    xor ah, ah
    mov al, [cs:drive0.FATs]
    mul word [cs:drive0.Sectors_Per_FAT]
    add ax, [cs:drive0.Reserved_Sectors]

    ; Restore the Cluster Offset.
    pop dx

    ; Root Directory Start + Cluster Offset.
    add ax, dx

    ; Save Root Directory Start + Cluster Offset.
    push ax

    ; Calculate the number of Root Directory Sectors.
    ; Root Directory Sectors = (Dir_Entries * 32) / Bytes_Per_Sector
    xor dx, dx
    mov ax, [cs:drive0.Dir_Entries]
    shl ax, 5
    div word [cs:drive0.Bytes_Per_Sector]

    ; Restore Root Directory Start + Cluster Offset.
    pop dx

    ; Root Directory Sectors + Root Directory Start + Cluster Offset
    add ax, dx

    ; Convert the Cluster's LBA to CHS.
    call _lba_to_chs

    ; Load the cluster into the _dosapi_cb
    stc
    mov ah, 0x02
    mov al, [cs:drive0.Sectors_Per_Cluster]
    mov dl, [cs:drive0.Drive_Number]
    mov es, [cs:_dosapi_seg]
    mov bx, _dosapi_cb
    int 0x13
    jc .fail

    mov ds, [cs:_dosapi_seg]
    mov si, _dosapi_cb
    mov es, [.buffer_segment]
    mov di, [.buffer_offset]

    ; Setup the counter.
    ; counter = bytes_to_read - read_bytes
    mov cx, [.bytes_to_read]
    sub cx, [.bytes_read]

    ; If the count is too big, make the counter the entire buffer.
    cmp cx, [.bytes_per_cluster]
    jbe .next

    mov cx, [.bytes_per_cluster]

.next:

    ; Add an offset pointer, if needed.
    cmp word [.pointer_offset], 0x0000
    je .read_cluster

    add si, [.pointer_offset]
    sub cx, [.pointer_offset]
    mov word [.pointer_offset], 0x0000

.read_cluster:

    movsb

    inc word [.buffer_offset]
    inc word [.bytes_read]
    inc word [gs:FCB.pointer]

    ; Make sure the pointer is within bounds.
    mov ax, [gs:FCB.pointer]
    cmp ax, [gs:FCB.file_size]
    jae .success

    loop .read_cluster

    ; FIX!!! Keeps looping.
    jmp .get_cluster

.success:
    ; Clear the caller's carry flag.
    and word [bp+6], 0xFFFE

    jmp .end

.fail:
    ; Set the caller's carry flag.
    or word [bp+6], 0x0001

.end:
    popa

    ; Return read bytes.
    mov ax, [.bytes_read]
    mov gs, [.old_gs]
    mov es, [.old_es]
    mov ds, [.buffer_segment]

    mov sp, bp
    pop bp
    iret
