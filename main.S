format ELF64 executable 3
entry _start

; TODO: remove unused consts after sys stuff done
UTSNAME_SYSNAME    = 0   ; OS
UTSNAME_NODENAME   = 65  ; hostname
UTSNAME_RELEASE    = 130 ; kernel
UTSNAME_VERSION    = 195
UTSNAME_MACHINE    = 260 ; arch
UTSNAME_DOMAINNAME = 325
UTSNAME_SIZE       = 390

SYS_UPTIME        = 0
SYS_LOADS         = 8   ; size 24 - 1, 5, 15 min load avgs
SYS_RAM_TOTAL     = 32
SYS_RAM_FREE      = 40
SYS_RAM_SHARED    = 48
SYS_RAM_BUFFER    = 56
SYS_SWAP_TOTAL    = 64
SYS_SWAP_FREE     = 72
SYS_PROCS         = 80  ; size 2 - number of processes
__PADDING         = 82  ; size 6
SYS_RAM_HIGH      = 88
SYS_RAM_HIGH_FREE = 96
SYS_MEM_UNIT      = 104
__PADDING         = 108 ; size 4
SYSINFO_SIZE      = 112

ITOABUF_SIZE = 32 ; large enough for 64-bit decimal + nl

SYS_WRITE   = 1
SYS_UNAME   = 63
SYS_EXIT    = 60
SYS_SYSINFO = 99

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
}

macro check_flag short, long, jump {
        mov rdi, [rsp + r12*8 + 8]
        mov rsi, short
        call streq
        test rax, rax
        jnz jump

        mov rdi, [rsp + r12*8 + 8]
        mov rsi, long
        call streq
        test rax, rax
        jnz jump
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

        uptime_label:
                db ESC, "[34m uptime"
                db ESC, "[0m", ":   "
        uptime_label_len = $ - uptime_label

        help_msg:
                db ESC, "[2;3mhttps://github.com/plumj-am/fasmfetch/issues", ESC, "[0m", NL
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

        day_suffix  db "d"
        hour_suffix db "h"
        min_suffix  db "m"
        sec_suffix  db "s"

        flag_h    db "-h", NUL
        flag_help db "--help", NUL

        flag_n         db "-n", NUL
        flag_no_header db "--no-header", NUL

segment readable writable
        init_envp dq 0

        no_header_flag db 0

        utsname_buf rb UTSNAME_SIZE
        sysinfo_buf rb SYSINFO_SIZE

        itoa_buf rb ITOABUF_SIZE


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
        ; find and store envp: skip argc, argv, NULL
        mov rbx, rsp
        mov rcx, [rsp]                 ; rcx = argc
        lea rbx, [rbx + rcx*8 + 16]    ; skip argc + argv[0..argc-1] + NULL

        mov [init_envp], rbx

        mov r12, 1                     ; i = 1 to skip argv[0]

.args_loop:
        cmp r12, [rsp]                 ; i > argc?
        jge .args_done

        check_flag flag_h, flag_help, .help
        check_flag flag_n, flag_no_header, .set_no_header

        jmp .args_next

.set_no_header:
        mov byte [no_header_flag], 1

.args_next:
        inc r12
        jmp .args_loop

.args_done:
        cmp byte [no_header_flag], 1
        je .fill_utsname
        ; fallthrough

.print_header:
        print welcome_msg, welcome_msg_len
        jmp .fill_utsname

.help:
        print help_msg, help_msg_len
        mov rax, SYS_EXIT
        xor rdi, rdi
        syscall

.fill_utsname:
        ; call uname once so everything can shared same buffer
        mov rax, SYS_UNAME
        mov rdi, utsname_buf
        syscall
        ; fallthrough

.fill_sysinfo:
        ; call uname once so everything can shared same buffer
        mov rax, SYS_SYSINFO
        mov rdi, sysinfo_buf
        syscall
        ; fallthrough

.run:
        call print_user_at_hostname
        call print_kernel
        call print_shell
        call print_term
        call print_editor
        call print_wm
        call print_uptime

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

; convert unsigned 64-bit int to decimal string
; in:       rax = number, rdi = output buffer (large needed)
; out:      rsi = buffer pointer (null terminated)
; clobbers: rax, rcx, rdx
itoa:
        mov rcx, 10                    ; divisor
        add rdi, 30                    ; build backwards from near end
        mov byte [rdi], 0              ; null term
.loop:
        xor rdx, rdx
        div rcx                        ; rax /= 10, rdx = digit
        add dl, '0'
        dec rdi
        mov [rdi], dl
        test rax, rax
        jnz .loop

        mov rsi, rdi                   ; rsi = string start
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

; in:       rax = total secs
; out:      nothing (stdout)
; clobbers: rax, rcx, rdx, rdi, rsi, r8, r9
print_duration:
        xor r9, r9                     ; tracks if we printed
        mov r8, rax                    ; r8 = total seconds
.days:
        mov rax, r8                    ; load remaining
        mov rcx, 86400
        xor rdx, rdx
        div rcx                        ; rax = days, rdx = remainder

        test rax, rax
        jz .hours                      ; skip to hours if 0

        mov r8, rdx                    ; save remainder

        mov rdi, itoa_buf
        call itoa
        mov rdi, rsi
        call print_str
        print day_suffix, 1

        mov r9, 1                      ; set printed flag
.hours:
        mov rax, r8
        mov rcx, 3600
        xor rdx, rdx
        div rcx                        ; rax = hours, rdx = remainder

        test rax, rax
        jz .minutes                    ; skip to minutes if 0

        mov r8, rdx                    ; save remainder

        cmp r9, 1                      ; if we printed days, need space
        jne .hours_print
        print space, 1
.hours_print:
        mov rdi, itoa_buf
        call itoa
        mov rdi, rsi
        call print_str
        print hour_suffix, 1

        mov r9, 1
.minutes:
        mov rax, r8
        mov rcx, 60
        xor rdx, rdx
        div rcx                        ; rax = minutes, rdx = remainder

        test rax, rax
        jz .seconds                    ; skip to seconds if 0

        mov r8, rdx                    ; save remainder

        cmp r9, 1                      ; if we printed days, need space
        jne .minutes_print
        print space, 1
.minutes_print:
        mov rdi, itoa_buf
        call itoa
        mov rdi, rsi
        call print_str
        print min_suffix, 1

        mov r9, 1
.seconds:
        mov rax, r8                    ; rax = remaining seconds should be <60

        test r9, r9                    ; check if printed d/h/m
        jnz .maybe_skip                ; if so, check if secs = 0

        jmp .print_seconds             ; must print even if 0
.maybe_skip:
        test rax, rax                  ; secs == 0?
        jz .done                       ; true + have higher units then done, skip secs
        print space, 1
.print_seconds:
        mov rdi, itoa_buf
        call itoa
        mov rdi, rsi
        call print_str
        print sec_suffix, 1
.done:
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
        ret

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
        ret

; TODO: format correctly, only shows seconds for now
; out: `uptime: 249882`
print_uptime:
        print uptime_label, uptime_label_len

        mov rax, qword [sysinfo_buf]   ; uptime offset 0 in struct
        call print_duration            ; rax = secs since boot

        print newline, 1
        ret
