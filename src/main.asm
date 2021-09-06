bits 16
org 0

segment .text

__start:

    ; Stop interrupts while changing the stack location to prevent corruption.
    cli

    ; Setup the stack.
    mov ax, 0x2000
    mov ss, ax
    xor ax, ax
    mov sp, ax
    mov bp, ax

    ; It's safe to resume the interrupts.
    sti

    cld

    ; Setup the segment pointers
    mov ax, 0x3000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

_main:

    push bp
    mov bp, sp

    ; Setup int 0x21 DOS API.
    call _dosapi_setup

    ; Setup the keyboard buffer.
    mov di, keyboard_buffer.max
    mov al, 0xFF
    stosb

    ; Setup the keyboard padding, just in case anything happens.
    mov di, keyboard_buffer.padding
    xor al, al
    stosb

    jmp .cmd_ver

.loop:
    mov dl, 0x0D
    mov ah, 0x02
    int 0x21

    ; Print a new line.
    mov dl, 0x0A
    mov ah, 0x02
    int 0x21

    ; Add prompt.
    mov dx, prompt_str
    mov ah, 0x09
    int 0x21

    ; Get buffered keyboard input.
    mov dx, keyboard_buffer
    mov ah, 0x0A
    int 0x21

    ; Pad the ending of the string.
    mov di, keyboard_buffer.buffer
    xor ah, ah
    mov al, [keyboard_buffer.read]
    add di, ax
    xor al, al
    stosb

    ; Check to see if this is the HELP command.
    mov di, keyboard_buffer.buffer
    mov si, cmd.help
    mov cx, 0x0005
    rep cmpsb
    je .cmd_help

    mov di, keyboard_buffer.buffer
    mov si, cmd.help_low
    mov cx, 0x0005
    rep cmpsb
    je .cmd_help

    ; Check to see if this is the VER command.
    mov di, keyboard_buffer.buffer
    mov si, cmd.ver
    mov cx, 0x0004
    rep cmpsb
    je .cmd_ver

    mov di, keyboard_buffer.buffer
    mov si, cmd.ver_low
    mov cx, 0x0004
    rep cmpsb
    je .cmd_ver

    ; Check to see if this is the CLS command.
    mov di, keyboard_buffer.buffer
    mov si, cmd.cls
    mov cx, 0x0004
    rep cmpsb
    je .cmd_cls

    mov di, keyboard_buffer.buffer
    mov si, cmd.cls_low
    mov cx, 0x0004
    rep cmpsb
    je .cmd_cls

    ; Check to see if this is the TYPE command.
    mov di, keyboard_buffer.buffer
    mov si, cmd.type
    mov cx, 0x0005
    rep cmpsb
    je .cmd_type

    mov di, keyboard_buffer.buffer
    mov si, cmd.type_low
    mov cx, 0x0005
    rep cmpsb
    je .cmd_type

    ; Check to see if this is the TYPE command.
    mov di, keyboard_buffer.buffer
    mov si, cmd.type_plus
    mov cx, 0x0005
    rep cmpsb
    je .cmd_type_plus

    mov di, keyboard_buffer.buffer
    mov si, cmd.type_plus_low
    mov cx, 0x0005
    rep cmpsb
    je .cmd_type_plus

    ; Is this a file?
    mov ax, 0x3D00
    mov dx, keyboard_buffer.buffer
    int 0x21
    jc .cmd_unknown

    ; Add COM file check!

    ; If it's a file, load it like a COM file.
    mov bx, ax
    mov dx, 0x6000
    mov ds, dx
    mov dx, 0x0100
    mov cx, 0xFEFF
    mov ah, 0x3F
    int 0x21
    jc .cmd_unknown

    ; Setup int 0x20
    mov ax, 0x2520
    mov ds, [cs:_dosapi_seg]
    mov dx, _main.com_ret
    int 0x21

    ; Save SP and BP.
    mov [_old_sp], sp
    mov [_old_bp], bp

    ; Stop interrupts while changing the stack location to prevent corruption.
    cli

    ; Setup the pointers and segments.
    mov ax, 0x6000
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ax, 0xFFFE
    mov sp, ax
    mov bp, ax

    ; It's safe to resume the interrupts.
    sti

    ; Change direction flag.
    cld

    ; Clear out the registers.
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx
    xor si, si
    xor di, di

    ; Call the COM file and hopefully it will return via int 0x20 or a retf.
    ; NOTE: Flags are not saved or predefined!
    call 0x6000:0x0100

.com_ret:
    ; Stop interrupts while changing the stack location to prevent corruption.
    cli

    ; Setup the pointers and segments.
    mov ax, 0x2000
    mov ss, ax
    mov ax, [cs:_dosapi_seg]
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov sp, [_old_sp]
    mov bp, [_old_bp]

    ; It's safe to resume the interrupts.
    sti

    jmp .loop

.cmd_unknown:
    ; Print help string.
    mov dx, unknown_str
    mov ah, 0x09
    int 0x21

    jmp .loop

.cmd_help:
    ; Print help string.
    mov dx, help_str
    mov ah, 0x09
    int 0x21

    jmp .loop

.cmd_type:
    ; Print type string.
    mov dx, type_str
    mov ah, 0x09
    int 0x21

    jmp .loop

.cmd_type_plus:
    ; Try to open the file.
    mov ax, 0x3D00
    mov dx, di
    int 0x21
    jnc .cmd_type_plus_skip

    ; Print type file invalid string.
    mov dx, type_invalid_str
    mov ah, 0x09
    int 0x21
    jmp .loop

.cmd_type_plus_skip:
    mov bx, ax
    mov ah, 0x3F
    mov cx, 0x1000
    mov dx, type_buffer
    int 0x021
    jnc .cmd_type_plus_skip2

    ; Print type file error string.
    mov dx, type_error_str
    mov ah, 0x09
    int 0x21
    jmp .loop

.cmd_type_plus_skip2:

    ; Add padding!
    mov dx, type_buffer
    add dx, ax
    mov bx, dx
    mov byte [bx], '$'

    mov dx, type_buffer
    mov ah, 0x09
    int 0x21

    jmp .loop

.cmd_ver:
    ; Print version string.
    mov dx, ver_str
    mov ah, 0x09
    int 0x21

    jmp .loop

.cmd_cls:
    ; Clear the screen with a form feed.
    mov dl, 0x0C
    mov ah, 0x02
    int 0x21

    jmp .loop

    mov sp, bp
    pop bp
    ret

segment .data

; All internal strings.
ver_str: db "LOCK OS 1.0", 0x0D, 0x0A, "$"
prompt_str: db ">>$"
unknown_str: db "UNKNOWN COMMAND OR FILE!", 0x0D, 0X0A, "$"
help_str:
db "CLS     CLEARS THE DISPLAY TERMINAL.", 0x0D, 0x0A
db "HELP    DISPLAYS THIS HELP MESSAGE.", 0x0D, 0X0A
db "TYPE    DISPLAYS THE CONTENTS OF A FILE.", 0x0D, 0x0A
db "VER     DISPLAYS THE CURRENT VERSION OF THE OS.", 0x0D, 0X0A
db "$"

type_str: db "NO FILE SPECIFIED!", 0x0D, 0x0A, "$"
type_invalid_str: db "UNABLE TO OPEN FILE!", 0x0D, 0x0A, "$"
type_error_str: db "UNABLE TO READ FILE!", 0x0D, 0x0A, "$"

file: db "test.txt", 0x00

; All command strings.
cmd:
.help:          db "HELP", 0x00
.help_low:      db "help", 0x00
.ver:           db "VER", 0x00
.ver_low:       db "ver", 0x00
.cls:           db "CLS", 0x00
.cls_low:       db "cls", 0x00
.type:          db "TYPE", 0x00
.type_low:      db "type", 0x00
.type_plus:     db "TYPE "
.type_plus_low: db "type "

segment .bss
keyboard_buffer:
.max: resb 0x01
.read: resb 0x01
.buffer: resb 0xFF
.padding: resb 0x001

type_buffer:
.buffer: resb 0x1000
.padding: resb 0x01

_old_sp: resw 0x01
_old_bp: resw 0x01

; Include DOS API library.
%include "./src/dosapi/dosapi.inc"
