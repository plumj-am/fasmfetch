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

ESC = 0x1B

NL  = 10 ; newline
NUL = 0  ; ASCII NUL

; clobbers: rax, rdi, rsi, rdx
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

macro from_env_bracket_pair key1, key2 {
.first:
        mov rdi, key1
        call getenv
        test rax, rax
        jz .done
        mov rdi, rax
        call print_str
.second:
        print space, 1
        mov rdi, key2
        call getenv
        test rax, rax
        jz .done
        mov rdi, rax
        call print_parens
.done:
        print newline, 1
        ret
}

segment readable
        space       db " "
        newline     db NL
        paren_open  db "("
        paren_close db ")"
        at_symbol   db "@"

        sep         db " ---", NL
        sep_len     = $ - sep

        ansi_rst     db ESC, "[0m"
        ansi_rst_len = $ - ansi_rst
        ansi_gre     db ESC, "[32m"
        ansi_gre_len = $ - ansi_gre
        ansi_yel     db ESC, "[33m"
        ansi_yel_len = $ - ansi_yel
        ansi_blu     db ESC, "[34m"
        ansi_blu_len = $ - ansi_blu
        ansi_mag     db ESC, "[35m"
        ansi_mag_len = $ - ansi_mag

        welcome_msg:
                db ESC, "[35m== fasmfetch =="
                db ESC, "[0m", NL
        welcome_msg_len = $ - welcome_msg

        system_label:
                db ESC, "[34m system"
                db ESC, "[0m", ":   "
        system_label_len = $ - system_label

        shell_label:
                db ESC, "[34m shell"
                db ESC, "[0m", ":    "
        shell_label_len = $ - shell_label

        term_label:
                db ESC, "[34m terminal"
                db ESC, "[0m", ": "
        term_label_len = $ - term_label

        editor_label:
                db ESC, "[34m editor"
                db ESC, "[0m", ":   "
        editor_label_len = $ - editor_label

        wm_label:
                db ESC, "[34m wm"
                db ESC, "[0m", ":       "
        wm_label_len = $ - wm_label

        help_msg:
                db ESC, "[2;3mhttps://github.com/plumj-am/fastfetch/issues", ESC, "[0m", NL
                db "usage:", NL
                db "  ", ESC, "[35mff", ESC, "[0m | ", ESC, "[35mfasmfetch", ESC, "[0m", " [options]", NL
                db NL
                db "options:", NL
                db "  -n  --no-header  Hide the 'fasmfetch' header from the output", NL
                db "  -h  --help       Show this help screen", NL
        help_msg_len = $ - help_msg

        user_key         db "USER", 0
        term_key         db "TERM", 0
        term_prog_key    db "TERM_PROGRAM", 0
        shell_key        db "SHELL", 0
        editor_key       db "EDITOR", 0
        visual_key       db "VISUAL", 0
        wm_key           db "XDG_CURRENT_DESKTOP", 0
        session_type_key db "XDG_SESSION_TYPE", 0

        flag_h    db "-h", NUL
        flag_help db "--help", NUL

        flag_n         db "-n", NUL
        flag_no_header db "--no-header", NUL

segment readable writable
        init_rsp  dq 0
        init_envp dq 0

        utsname_buf rb UTSNAME_SIZE

segment readable executable
;======================================
; main execution procedure
;
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
;======================================
_start:
        mov [init_rsp], rsp

        ; find and store envp: skip argc, argv, NULL
        mov rbx, [init_rsp]
        mov rcx, [rbx]                 ; rcx = argc
        lea rbx, [rbx + rcx*8 + 16]    ; skip argc + argv[0..argc-1] + NULL
        mov [init_envp], rbx

        ; argc at [rsp], argv[1] at [rsp+16] as described above
        cmp qword [rsp], 1             ; argc > 1?
        jle .print_header

        check_flag 16, flag_h, flag_help,      .help
        check_flag 16, flag_n, flag_no_header, .fill_utsname
        ; fallthrough is intentional
        ; default to help if check_flag doesn't jmp somewhere

.help:
        print help_msg, help_msg_len
        mov rax, SYS_EXIT
        xor rdi, rdi
        syscall

.print_header:
        print welcome_msg, welcome_msg_len
        ; fallthrough

.fill_utsname:
        ; call uname once so everything can shared same buffer
        mov rax, SYS_UNAME
        mov rdi, utsname_buf
        syscall
        ; fallthrough

.run:
        call print_user_at_hostname
        call print_kernel
        call print_shell
        call print_term
        call print_editor
        call print_wm

        mov rax, SYS_EXIT
        xor rdi, rdi                   ; exit code 0 (xor smaller than `mov rdi, 0`)
        syscall

;======================================
; print helper procedures
;======================================

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

;======================================
; string procedures
;======================================

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

;======================================
; helper procedures
;======================================

; search envp for a null-terminated key
;   in:       rdi = pointer to key string e.g. "USER"
;   out:      rax = pointer to value after the "=", or 0 if not found
;   clobbers: rax, rbx, rcx, rdx, rsi, rdi
getenv:
        mov rbx, [init_envp]
.loop:
        mov rax, [rbx]                 ; load envp entry pointer
        test rax, rax
        jz .notfound

        ; compare key with current env val
        mov rsi, rdi                   ; key pointer
        mov rdx, rax                   ; val pointer
.cmp:
        mov cl, [rsi]
        test cl, cl
        jz .match_check                ; end of key, check for "="
        cmp cl, [rdx]
        jne .next
        inc rsi
        inc rdx
        jmp .cmp
.match_check:
        cmp byte [rdx], '='
        jne .next
        inc rdx                        ; point past "="
        mov rax, rdx
        ret
.next:
        add rbx, 8
        jmp .loop
.notfound:
        xor rax, rax
        ret

;======================================
; data output procedures
;======================================

; out: `jam`
print_user:
        print ansi_gre, ansi_gre_len
        print space, 1

        mov rdi, user_key
        call getenv
        test rax, rax
        jz .done
        mov rdi, rax
        call print_str
.done:
        print ansi_rst, ansi_rst_len
        ret

; out: `yuzu`
print_hostname:
        mov rdi, utsname_buf + UTSNAME_NODENAME
        call print_str
        ret

; out: `jam@yuzu`
print_user_at_hostname:
        call print_user
        print at_symbol, 1
        print ansi_blu, ansi_blu_len
        call print_hostname
        print ansi_rst, ansi_rst_len
        print newline, 1
        print sep, sep_len
        ret

; out: `system: Linux 6.19.12-zen1 (x86_64)`
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

; out: `shell: <path>`
print_shell:
        print shell_label, shell_label_len

        mov rdi, shell_key
        call getenv
        test rax, rax
        jz .done
        mov rdi, rax
        call print_str
.done:
        print newline, 1
        ret

; out: `terminal: xterm-kitty (zellij)`
print_term:
        print term_label, term_label_len
        from_env_bracket_pair term_key, term_prog_key

; out: `editor: hx`
print_editor:
        print editor_label, editor_label_len

        mov rdi, editor_key
        call getenv
        test rax, rax
        jnz .found

        mov rdi, visual_key
        call getenv
        test rax, rax
        jz .done
.found:
        mov rdi, rax
        call print_str
.done:
        print newline, 1
        ret

; out: `wm: niri (wayland)`
print_wm:
        print wm_label, wm_label_len
        from_env_bracket_pair wm_key, session_type_key
