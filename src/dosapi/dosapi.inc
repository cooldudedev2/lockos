; dosapi internals
%include "./src/dosapi/dosapi.asm"
%include "./src/dosapi/dosapi_setup.asm"

; Standard I/O
%include "./src/dosapi/char_stdin.asm"
%include "./src/dosapi/buffer_stdin.asm"
%include "./src/dosapi/char_stdout.asm"
%include "./src/dosapi/string_stdout.asm"

; File I/O
%include "./src/dosapi/open_file_handle.asm"
%include "./src/dosapi/read_file_handle.asm"
%include "./src/dosapi/close_file_handle.asm"
%include "./src/dosapi/file_exists_handle.asm"
%include "./src/dosapi/init_drive.asm"
%include "./src/dosapi/lba_to_chs.asm"
%include "./src/dosapi/load_root.asm"
%include "./src/dosapi/load_fat.asm"

; IVT
%include "./src/dosapi/set_interrupt.asm"
%include "./src/dosapi/get_interrupt.asm"

; Memory Management
%include "./src/dosapi/alloc_mem.asm"
%include "./src/dosapi/free_mem.asm"
