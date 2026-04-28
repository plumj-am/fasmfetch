format ELF64 executable 3
entry _start

segment readable
        msg db "Welcome to fasmfetch!", 10
        msg_len = $ - msg

segment readable executable
_start:
        mov rax, 1
        mov rdi, 1
        mov rsi, msg
        mov rdx, msg_len
        syscall

        mov rax, 60
        mov rdi, 0
        syscall
