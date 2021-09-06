segment .text

; Initializes drive A:
_init_drive:

    pusha

    ; Get the drive'SUBB A,  parameters.
    xor dl, dl
    mov ah, 0x08
    int 0x13

    ; Save sectors per track.
    xor ch, ch
    mov [drive0.Sectors_Per_Track], cx

    ; Save the number of heads.
    inc dh
    shr dx, 8
    mov [drive0.Sides], dx

    ; Load the bootloader that contains the EBPB.
    xor ax, ax
    call _lba_to_chs

    mov ax, 0x0201
    xor dl, dl
    mov bx, [cs:_dosapi_seg]
    mov es, bx
    mov bx, _dosapi_fb
    int 0x13

    ; Save BPB information into our drive0 array.
    mov si, _dosapi_fb
    add si, 0x03
    mov di, drive0

    mov bx, [cs:_dosapi_seg]
    mov ds, bx
    mov es, bx

    ; The size of the EPBP is  0x3B (59) bytes.
    mov cx, 0x3B

    rep movsb

    ; Save the root directory's LBA.
    ; Root Directory = (Sectors_Per_FAT * FATs) + Reserved_Sectors
    xor dx, dx
    xor ah, ah
    mov al, [drive0.FATs]
    mul word [drive0.Sectors_Per_FAT]
    add ax, [drive0.Reserved_Sectors]
    mov [drive0.root_dir], ax

    ; Save the root directory's LBA size.
    ; Root Directory Sectors = (Dir_Entries * 32) / Bytes_Per_Sector
    xor dx, dx
    mov ax, [drive0.Dir_Entries]
    shl ax, 5
    div word [drive0.Bytes_Per_Sector]
    mov [drive0.root_dir_sectors], ax

    popa
    ret

segment .bss

drive0:
; EPBP
.OEM_Label: resb 0x08
.Bytes_Per_Sector: resw 0x01
.Sectors_Per_Cluster: resb 0x01
.Reserved_Sectors: resw 0x01
.FATs: resb 0x01
.Dir_Entries: resw 0x01
.Logical_Sectors: resw 0x01
.Media_ID: resb 0x01
.Sectors_Per_FAT: resw 0x01
.Sectors_Per_Track: resw 0x01
.Sides: resw 0x01
.Hidden_Sectors: resd 0x01
.LBA_Sectors: resd 0x01
.Drive_Number: resb 0x01
.Windows_NT_Flag: resb 0x01
.Signature: resb 0x01
.Volume_ID: resd 0x01
.Volume_Label: resb 0x0B
.Identifier: resb 0x08

; Other meta data.
.root_dir: resw 0x01
.root_dir_sectors: resw 0x01
