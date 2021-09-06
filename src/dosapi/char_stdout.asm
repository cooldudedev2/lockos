segment .text

_char_stdout:
    push es
    push ds
    push bp
    mov bp, sp
    sub sp, 2
    pusha

    push dx

    ; Setup the data segment.
    mov ds, [cs:_dosapi_seg]

    ; ES:DI points to the BIOS video memory array.
    mov ax, 0xB800
    mov es, ax
    mov ax, [cs:.row]
    mov bx, 80
    mul bx
    mov di, [cs:.col]
    add di, ax
    shl di, 1

    pop ax

    ; Don't print a null character.
    cmp al, 0x00
    je .done

    ; Handle a back space.
    cmp al, 0x08
    je .backspace

    ; Handle a line feed.
    cmp al, 0x0A
    je .linefeed

    ; Handle a form feed.
    cmp al, 0x0C
    je .formfeed

    ; Handle a carriage return.
    cmp al, 0x0D
    je .carriage_return

    ; Set the color.
    mov ah, [.color]

    ; Write the character into the BIOS video memory array.
    stosw

    ; Increase the column counter.
    inc word [.col]

    jmp .done

.carriage_return:
    mov word [.col], 0x0000
    jmp .done

.linefeed:
    inc word [.row]
    jmp .done

.formfeed:

    ; Reset the counters.
    mov word [.col], 0x0000
    mov word [.row], 0x0000

    ; Point to the beginning of BIOS video memory.
    xor di, di

    ; Blank space.
    mov ah, [.color]
    mov al, ' '

    ; 80 * 25 = 2000
    mov cx, 0x07D0

    ; Clear out the entire screen.
    rep stosw

    jmp .done

.backspace:
    ; Make sure we're not out of bounds of the screen.
    cmp word [.col], 0x00
    jne .skip

    cmp word [.row], 0x00
    je .done

    dec word [.row]
    mov word [.col], 0x50

.skip:
    dec word [.col]

    ; Set the color.
    mov ah, [.color]
    mov al, ' '

    ; Back up one word.
    sub di, 2

    ; Write the character into the BIOS video memory array.
    stosw

.done:
    ; Move to a new line if the row is full.
    cmp word [.col], 80
    jb .skip2

    mov word [.col], 0x0000
    inc word [.row]

.skip2:
    ; Scroll up a line if we're over the counter.
    cmp word [.row], 25
    jb .skip3

    ; Scroll down one.
    dec word [.row]

    ; Save DS.
    mov [bp-2], ds

    ; DS now points at BIOS video memory.
    mov ax, es
    mov ds, ax

    ; Point DI at memory array and SI one row above memory array.
    xor di, di
    mov si, 0x00A0
    mov cx, 0x0F00

    ; Move all the characters down by one row.
    rep movsw

    ; Restore old DS.
    mov ds, [bp-2]

.skip3:
    mov ax, [.row]
    mov bx, 80
    mul bx
    mov bx, [.col]
    add bx, ax

    ; Move the cursor.
	mov dx, 0x03D4
	mov al, 0x0F
	out dx, al

	inc dl
	mov al, bl
	out dx, al

	dec dl
	mov al, 0x0E
	out dx, al

	inc dl
	mov al, bh
	out dx, al

    popa
    mov sp, bp
    pop bp
    pop ds
    pop es
    iret

segment .data

.color: db 0x07
.col: dw 0x0000
.row: dw 0x0000
