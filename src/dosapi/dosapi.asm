segment .text

_dosapi:

    ; Compare the function number and jump to it.
    cmp ah, 0x01
    je _char_stdin

    cmp ah, 0x02
    je _char_stdout

    cmp ah, 0x09
    je _string_stdout

    cmp ah, 0x0A
    je _buffer_stdin

    cmp ah, 0x25
    je _set_interrupt

    cmp ah, 0x35
    je _get_interrupt

    cmp ah, 0x3D
    je _open_file_handle

    cmp ah, 0x3E
    je _close_file_handle

    cmp ah, 0x3F
    je _read_file_handle

    cmp ah, 0x48
    je _alloc_mem

    cmp ah, 0x49
    je _free_mem

    ; Invalid function number!
    ; Stop!
    jmp $

segment .bss

; Start of bss segment.
_dosapi_bss_start:

_dosapi_seg: resw 0x01      ; Current segment for dosapi library.
_dosapi_fb: resb 0x2000     ; File buffer.
_dosapi_cb: resb 0x1000     ; Cluster buffer for file I/O
_dosapi_mem_seg: resw 0x01  ; Segment for the dos api memory management.
_dosapi_mem: resb 0x200     ; Bitchain of free and used paragraphs.
_dosapi_files: resw 0xFF    ; A list of pointers to the file handle's FCB.

; End of bss segment.
_dosapi_bss_end:
