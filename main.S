format ELF64 executable 3
entry _start

; palette:
; "[0m"  - reset
; "[35m" - magenta
; "[34m" - blue

segment readable
        space   db " "
        newline db 10

        welcome_msg:
                db "Welcome to "
                db 0x1B, "[35mfasmfetch"
                db 0x1B, "[0m!", 10, 10
        welcome_msg_len = $ - welcome_msg

        hostname_label:
                db 0x1B, "[34mhostname"
                db 0x1B, "[0m", ": "
        hostname_label_len = $ - hostname_label

        kernel_label:
                db 0x1B, "[34mkernel"
                db 0x1B, "[0m", ":   "
        kernel_label_len = $ - kernel_label

segment readable writable
        ; 6*65 bytes for full utsname struct
        ; offsets:
        ;   0 = sysname (OS name)
        ;  65 = nodename (hostname)
        ; 130 = release (kernel)
        ; 195 = version (exact)
        ; 260 = machine (architecture)
        ; 325 = domainname
        utsname_buf rb 390

segment readable executable
_start:
        ; call uname once so everything can shared same buffer
        mov rax, 63
        mov rdi, utsname_buf
        syscall

        mov rax, 1
        mov rdi, 1
        mov rsi, welcome_msg
        mov rdx, welcome_msg_len
        syscall

        call print_hostname
        call print_kernel

        mov rax, 60
        xor rdi, rdi                   ; exit code 0 (xor smaller than `mov rdi, 0`)
        syscall

print_space:
        mov rax, 1
        mov rdi, 1
        mov rsi, space
        mov rdx, 1
        syscall
        ret


; scan for null terminator
;   in:  rdi = pointer to string
;   out: rax = length (excluding null)
strlen:
        xor rax, rax
.loop:
        ; scan forward from base pointer by inc rax avoids need for 2 registers
        cmp byte [rdi + rax], 0
        je .done
        inc rax
        jmp .loop
.done:
        ret

print_hostname:
        mov rax, 1
        mov rdi, 1
        mov rsi, hostname_label
        mov rdx, hostname_label_len
        syscall

        ; measure hostname length
        mov rdi, utsname_buf + 65      ; nodename offset 65 in struct
        call strlen

        mov rdx, rax                   ; length now in rax
        mov rax, 1
        mov rdi, 1
        mov rsi, utsname_buf + 65
        syscall

        mov rax, 1
        mov rdi, 1
        mov rsi, newline
        mov rdx, 1
        syscall

        ret

print_kernel:
        mov rax, 1
        mov rdi, 1
        mov rsi, kernel_label
        mov rdx, kernel_label_len
        syscall

        mov rdi, utsname_buf           ; sysname offset 0 in struct
        call strlen

        mov rdx, rax                   ; length now in rax
        mov rax, 1
        mov rdi, 1
        mov rsi, utsname_buf
        syscall

        call print_space

        mov rdi, utsname_buf + 130     ; release offset 130 in struct
        call strlen

        mov rdx, rax                   ; length now in rax
        mov rax, 1
        mov rdi, 1
        mov rsi, utsname_buf + 130
        syscall

        mov rax, 1
        mov rdi, 1
        mov rsi, newline
        mov rdx, 1
        syscall

        ret


