format ELF64 executable 3
entry _start

; palette:
; "[0m"  - reset
; "[35m" - magenta
; "[34m" - blue

segment readable
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

segment readable writable
        ; 6*65 bytes for full utsname struct - only interested in nodename for
        ; now but also has: sysname, release, machine, etc. so will be useful
        ; later
        utsname_buf rb 390

segment readable executable
_start:
        mov rax, 1
        mov rdi, 1
        mov rsi, welcome_msg
        mov rdx, welcome_msg_len
        syscall

        call print_hostname

        mov rax, 60
        xor rdi, rdi                   ; exit code 0 (xor smaller than `mov rdi, 0`)
        syscall

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
        mov rax, 63                    ; syscall 63 = uname
        mov rdi, utsname_buf
        syscall

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


