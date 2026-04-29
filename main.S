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

macro check_flag pos, short, long, jump {
        mov rdi, [rsp + pos]
        mov rsi, short
        call streq
        test rax, rax
        jnz jump

        mov rdi, [rsp + pos]
        mov rsi, long
        call streq
        test rax, rax
        jnz jump
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
                db 0x1B, "[35m== fasmfetch =="
                db 0x1B, "[0m", 10
        welcome_msg_len = $ - welcome_msg

        hostname_label:
                db 0x1B, "[34mhostname"
                db 0x1B, "[0m", ": "
        hostname_label_len = $ - hostname_label

        system_label:
                db 0x1B, "[34msystem"
                db 0x1B, "[0m", ":   "
        system_label_len = $ - system_label

        flag_h    db "-h", 0
        flag_help db "--help", 0
        help_msg:
                db "github:plumj-am/fastfetch", 10
                db "usage: ", 0x1B, "[35mfasmfetch", 0x1B, "[0m", " <ARGS>", 10
                db 10
                db "-h  --help     Show this help screen"
        help_msg_len = $ - help_msg

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

        ; argc at [rsp], argv[1] at [rsp+16] as described above
        cmp qword [rsp], 1             ; argc > 1?
        jle .run

        check_flag 16, flag_h, flag_help, .help
        ; fallthrough is intentional
        ; default to help if check_flag doesn't jmp somewhere

.help:
        print help_msg, help_msg_len
        mov rax, SYS_EXIT
        xor rdi, rdi
        syscall

.run:
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

; compare two null-terminated strings
;   in:       rdi = string a, rsi = string b
;   out:      rax = 1 if eq, otherwise 0
;   clobbers: al, dl, rcx
streq:
        xor rcx, rcx
.loop:
        mov al, [rdi + rcx]
        mov dl, [rsi + rcx]
        cmp al, dl
        jne .no
        test al, al                    ; both zero -> end of both strings
        jz .yes
        inc rcx
        jmp .loop
.yes:
        mov rax, 1
        ret
.no:
        xor rax, rax
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
