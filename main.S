format ELF64 executable 3
entry _start

UTSNAME_SYSNAME    = 0   ; OS
UTSNAME_NODENAME   = 65  ; hostname
UTSNAME_RELEASE    = 130 ; kernel
UTSNAME_VERSION    = 195
UTSNAME_MACHINE    = 260 ; arch
UTSNAME_DOMAINNAME = 325
UTSNAME_SIZE       = 390

SYS_WRITE = 1
SYS_UNAME = 63
SYS_EXIT  = 60

macro print str, len {
        mov rax, SYS_WRITE
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
        init_rsp dq 0

        utsname_buf rb UTSNAME_SIZE

segment readable executable
; stack at entry
;    [rsp]              - argc (program args count)
;    [rsp + 8]          - argv[0] (program name)
;    ...                - argv[1..argc-1] (program args)
;    [rsp + (argc+1)*8] - null
;    [rsp + (argc+2)*8] - env strings start
;    ...
;    null               - envp end
; where
;    rsp  = register stack pointer
;    envp = environment pointer
_start:
        mov [init_rsp], rsp

        ; call uname once so everything can shared same buffer
        mov rax, SYS_UNAME
        mov rdi, utsname_buf
        syscall

        print welcome_msg, welcome_msg_len

        call print_hostname
        call print_kernel

        mov rax, SYS_EXIT
        xor rdi, rdi                   ; exit code 0 (xor smaller than `mov rdi, 0`)
        syscall

; print null-terminated string
;   in:       rdi = pointer to string
;   clobbers: rax, rsi, rdx
print_str:
        call strlen                    ; rax = len, rdi intact
        mov rsi, rdi                   ; pointer to rsi for write
        mov rdx, rax
        mov rax, SYS_WRITE
        mov rdi, 1
        syscall
        ret

; prints ( [color]str[reset] )
;   in:       rdi = pointer to null-terminated string
;   clobbers: rax, rdi, rsi, rdx
print_parens:
        push rdi                       ; save string pointer across calls

        print paren_open, 1

        print ansi_yel, ansi_yel_len

        pop rdi                        ; restore string pointer
        call print_str

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

        mov rdi, utsname_buf + UTSNAME_NODENAME
        call print_str

        print newline, 1
        ret

; out: `system:      Linux 6.19.12-zen1 (x86_64)`
print_kernel:
        print system_label, system_label_len

        mov rdi, utsname_buf           ; sysname offset 0 in struct
        call print_str

        print space, 1

        mov rdi, utsname_buf + UTSNAME_RELEASE
        call print_str

        print space, 1

        mov rdi, utsname_buf + UTSNAME_MACHINE
        call print_parens

        print newline, 1
        ret
