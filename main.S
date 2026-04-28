format ELF64 executable 3
entry _start

; palette:
; "[0m"  - reset
; "[35m" - magenta
; "[34m" - blue
; "[33m" - yellow

macro print str, len {
        mov rax, 1
        mov rdi, 1
        mov rsi, str
        mov rdx, len
        syscall
}

segment readable
        space       db " "
        newline     db 10
        paren_open  db "("
        paren_close db ")"

        ansi_rst     db 0x1B, "[0m"
        ansi_rst_len = $ - ansi_rst
        ansi_yel     db 0x1B, "[33m"
        ansi_yel_len = $ - ansi_yel

        welcome_msg:
                db "Welcome to "
                db 0x1B, "[35mfasmfetch"
                db 0x1B, "[0m!", 10, 10
        welcome_msg_len = $ - welcome_msg

        hostname_label:
                db 0x1B, "[34mhostname"
                db 0x1B, "[0m", ": "
        hostname_label_len = $ - hostname_label

        system_label:
                db 0x1B, "[34msystem"
                db 0x1B, "[0m", ":   "
        system_label_len = $ - system_label

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

        print welcome_msg, welcome_msg_len

        call print_hostname
        call print_kernel

        mov rax, 60
        xor rdi, rdi                   ; exit code 0 (xor smaller than `mov rdi, 0`)
        syscall

; prints ( [color]str[reset] )
;   in:       rdi = pointer to null-terminated string
;   clobbers: rax, rdx, rsi
print_parens:
        push rdi                       ; save string pointer across calls

        print paren_open, 1

        print ansi_yel, ansi_yel_len

        pop rdi                        ; restore string pointer
        push rdi                       ; save again for the write call
        call strlen

        pop rsi                        ; string pointer -> rsi for write
        mov rdx, rax                   ; length now in rax
        mov rax, 1
        mov rdi, 1
        syscall

        print ansi_rst, ansi_rst_len
        print paren_close, 1

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

; out: `hostname: yuzu`
print_hostname:
        print hostname_label, hostname_label_len

        mov rdi, utsname_buf + 65      ; nodename offset 65 in struct
        call strlen

        mov rdx, rax                   ; length now in rax
        mov rax, 1
        mov rdi, 1
        mov rsi, utsname_buf + 65
        syscall

        print newline, 1

        ret

; out: `system:      Linux 6.19.12-zen1 (x86_64)`
print_kernel:
        print system_label, system_label_len

        mov rdi, utsname_buf           ; sysname offset 0 in struct
        call strlen

        mov rdx, rax                   ; length now in rax
        mov rax, 1
        mov rdi, 1
        mov rsi, utsname_buf
        syscall

        print space, 1

        mov rdi, utsname_buf + 130     ; release offset 130 in struct
        call strlen

        mov rdx, rax                   ; length now in rax
        mov rax, 1
        mov rdi, 1
        mov rsi, utsname_buf + 130
        syscall

        print space, 1

        mov rdi, utsname_buf + 260     ; arch offset 260 in struct

        call print_parens

        print newline, 1

        ret
