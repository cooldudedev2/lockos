segment .text

; Bootloader's LBA to CHS function.
; Converts LBA to CHS for BIOS disk functions.
; IN: AX- LBA
; OUT: CL - Sector Number
;      CH - Cylinder Number
;      DH - Head Number

; NOTE: convert to cdel format.
;       Maybe store CHS in FCB to deal with multiple returns?
_lba_to_chs:
    push ax
    push bx

    ; Find the Sector Number.
    ; Sector Number = (LBA % Sectors_Per_Track) + 1
    xor dx, dx
    div word [cs:drive0.Sectors_Per_Track]
    inc dl

    ; Move the Sector Number to the appropriate return register.
    mov cl, dl

    ; Find the Cylinder Number and Head Number.
    ; Cylinder Number = (LBA / Sector_Per_Tracks) / Sides
    ; Head Number = (LBA / Sector_Per_Tracks) % Sides
    xor dx, dx
    div word [cs:drive0.Sides]
    mov ch, al
    shl dx, 8

    pop bx
    pop ax

    ret
