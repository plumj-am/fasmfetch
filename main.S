format ELF64 executable 3
entry _start

segment readable
        ; palette:
        ; "[0m"  - reset
        ; "[35m" - magenta
        ; "[34m" - blue
        welcome_msg:
                db "Welcome to "
                db 0x1B, "[35mfasmfetch"
                db 0x1B, "[0m!"
                db 10
        welcome_msg_len = $ - welcome_msg

segment readable executable
_start:
        mov rax, 1
        mov rdi, 1
        mov rsi, welcome_msg
        mov rdx, welcome_msg_len
        syscall

        mov rax, 60
        xor rdi, rdi                   ; exit code 0 (xor smaller than `mov rdi, 0`)
        syscall
