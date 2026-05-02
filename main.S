format ELF64 executable 3
entry _start

; TODO: remove unused consts after sys stuff done
UTSNAME_SYSNAME    = 0   ; OS
UTSNAME_NODENAME   = 65  ; hostname
UTSNAME_RELEASE    = 130 ; kernel
UTSNAME_MACHINE    = 260 ; size 65 - arch

SYS_UPTIME        = 0
SYS_RAM_TOTAL     = 32
SYS_RAM_FREE      = 40
SYS_RAM_BUFFER    = 56
SYS_SWAP_TOTAL    = 64
SYS_SWAP_FREE     = 72
SYS_PROCS         = 80  ; size 2 - number of processes

SYS_WRITE   = 1
SYS_UNAME   = 63
SYS_EXIT    = 60
SYS_SYSINFO = 99

; show mask bit flags
; NOTE: idk if best way
; it's just 1,2,4,8,...
SHOW_KERNEL = 1 shl 0                  ; shl = shift left
SHOW_SHELL  = 1 shl 1
SHOW_TERM   = 1 shl 2
SHOW_EDITOR = 1 shl 3
SHOW_WM     = 1 shl 4
SHOW_UPTIME = 1 shl 5
SHOW_PROCS  = 1 shl 6
SHOW_RAM    = 1 shl 7
SHOW_SWAP   = 1 shl 8
SHOW_ALL    = (1 shl 9) - 1            ; mask all enabled

ESC = 0x1B

NL  = 10 ; newline
NUL = 0  ; ASCII NUL

; print a string
;   clobbers: rax, rdi, rsi, rdx
macro print str, len {
        push rcx
        push r11
        mov rax, SYS_WRITE
        mov rdi, 1
        mov rsi, str
        mov rdx, len
        syscall
        pop r11
        pop rcx
}

; get 2 environment variable values by key and print as `key1 (key2)`
;   in: key1, key2
macro from_env_bracket_pair key1, key2 {
local .first, .second, .done           ; prevent name collisions
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

; check if a flag is present in args
;   in: short variant, long variant, jump location on success
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

; check if --no-* flag is present, clear corresponding bit in show_mask
; check if a hide flag (short or long) is present, clear bit in show_mask
;   in: short flag string, long flag string, bit constant
macro check_hide short, long, bit {
local .clear, .skip
        mov rdi, [rsp + r12*8 + 8]
        mov rsi, short
        call streq
        test rax, rax
        jnz .clear

        mov rdi, [rsp + r12*8 + 8]
        mov rsi, long
        call streq
        test rax, rax
        jz .skip

.clear:
        mov rax, bit
        not rax
        and [show_mask], rax
.skip:
}

segment readable
        space       db " "
        newline     db NL
        paren_open  db "("
        paren_close db ")"
        at_symbol   db "@"
        slash       db "/"

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

        procs_label:
                db ESC, "[34m procs"
                db ESC, "[0m", ":    "
        procs_label_len = $ - procs_label

        ram_label:
                db ESC, "[34m ram"
                db ESC, "[0m", ":      "
        ram_label_len = $ - ram_label

        swap_label:
                db ESC, "[34m swap"
                db ESC, "[0m", ":     "
        swap_label_len = $ - swap_label

        gb_suffix:
                db ESC, "[33m GiB"
                db ESC, "[0m"
        gb_suffix_len = $ - gb_suffix

        help_msg:
                db ESC, "[2;3mhttps://github.com/plumj-am/fasmfetch/issues", ESC, "[0m", NL
                db "usage:", NL
                db "  ", ESC, "[35mff", ESC, "[0m | ", ESC, "[35mfasmfetch", ESC, "[0m", " [options]", NL
                db NL
                db "options:", NL
                db "  -n   --no-header  Hide the 'fasmfetch' header from the output", NL
                db "  -nk  --no-kernel  Hide the kernel line", NL
                db "  -ns  --no-shell   Hide the shell line", NL
                db "  -nt  --no-term    Hide the terminal line", NL
                db "  -ne  --no-editor  Hide the editor line", NL
                db "  -nw  --no-wm      Hide the wm line", NL
                db "  -nu  --no-uptime  Hide the uptime line", NL
                db "  -np  --no-procs   Hide the procs line", NL
                db "  -nr  --no-ram     Hide the ram line", NL
                db "  -na  --no-swap    Hide the swap line", NL
                db NL
                db "  -h   --help       Show this help screen", NL
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

        flag_n         db "-n",          NUL
        flag_no_header db "--no-header", NUL
        flag_nk        db "-nk",         NUL
        flag_no_kernel db "--no-kernel", NUL
        flag_ns        db "-ns",         NUL
        flag_no_shell  db "--no-shell",  NUL
        flag_nt        db "-nt",         NUL
        flag_no_term   db "--no-term",   NUL
        flag_ne        db "-ne",         NUL
        flag_no_editor db "--no-editor", NUL
        flag_nw        db "-nw",         NUL
        flag_no_wm     db "--no-wm",     NUL
        flag_nu        db "-nu",         NUL
        flag_no_uptime db "--no-uptime", NUL
        flag_np        db "-np",         NUL
        flag_no_procs  db "--no-procs",  NUL
        flag_nr        db "-nr",         NUL
        flag_no_ram    db "--no-ram",    NUL
        flag_na        db "-na",         NUL
        flag_no_swap   db "--no-swap",   NUL
        flag_h         db "-h",          NUL
        flag_help      db "--help",      NUL


segment readable writable
        init_envp dq 0

        no_header_flag db 0
        show_mask      dq SHOW_ALL     ; show all lines by default

        utsname_buf rb 390
        sysinfo_buf rb 112

        itoa_buf rb 32 ; large enough for 64-bit decimal + nl


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

        check_hide flag_nk, flag_no_kernel, SHOW_KERNEL
        check_hide flag_ns, flag_no_shell,  SHOW_SHELL
        check_hide flag_nt, flag_no_term,   SHOW_TERM
        check_hide flag_ne, flag_no_editor, SHOW_EDITOR
        check_hide flag_nw, flag_no_wm,     SHOW_WM
        check_hide flag_nu, flag_no_uptime, SHOW_UPTIME
        check_hide flag_np, flag_no_procs,  SHOW_PROCS
        check_hide flag_nr, flag_no_ram,    SHOW_RAM
        check_hide flag_na, flag_no_swap,   SHOW_SWAP

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

        test [show_mask], SHOW_KERNEL
        jz .skip_kernel
        call print_kernel

; I think the order is ok lmao
; NOTE: check order correct when adding new stuff
.skip_kernel:
        test [show_mask], SHOW_SHELL
        jz .skip_shell
        call print_shell

.skip_shell:
        test [show_mask], SHOW_TERM
        jz .skip_term
        call print_term

.skip_term:
        test [show_mask], SHOW_EDITOR
        jz .skip_editor
        call print_editor

.skip_editor:
        test [show_mask], SHOW_WM
        jz .skip_wm
        call print_wm

.skip_wm:
        test [show_mask], SHOW_UPTIME
        jz .skip_uptime
        call print_uptime

.skip_uptime:
        test [show_mask], SHOW_PROCS
        jz .skip_procs
        call print_procs

.skip_procs:
        test [show_mask], SHOW_RAM
        jz .skip_ram
        call print_ram

.skip_ram:
        test [show_mask], SHOW_SWAP
        jz .skip_swap
        call print_swap

.skip_swap:
        mov rax, SYS_EXIT
        xor rdi, rdi                   ; exit code 0 (xor smaller than `mov rdi, 0`)
        syscall

;======================================
; print helper procedures
;======================================

; print null-terminated string
;   in:       rdi = pointer to string
;   clobbers: rax, rdi, rsi, rdx, r11
print_str:
        push rcx
        call strlen                    ; rax = len, rdi intact
        mov rsi, rdi                   ; pointer to rsi for write
        mov rdx, rax
        mov rax, SYS_WRITE
        mov rdi, 1
        syscall
        pop rcx
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
;   clobbers: rdx, rcx
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
;   in:       rax = number, rdi = output buffer (large needed)
;   out:      rsi = buffer pointer (null terminated)
;   clobbers: rax, rcx, rdx, rdi
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
;   clobbers: rax, rbx, rcx, rdx, rsi
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

; print formatted duration as days hours minutes seconds
;   in:       rax = total secs
;   out:      nothing (stdout)
;   clobbers: rax, rcx, rdx, rdi, rsi, r8, r9, r11
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
        push rax
        print space, 1
        pop rax
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
        push rax
        print space, 1
        pop rax
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
        push rax
        print space, 1
        pop rax
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

; out: `uptime: 3d 2h 12m 18s`
print_uptime:
        print uptime_label, uptime_label_len

        mov rax, qword [sysinfo_buf]   ; uptime offset 0 in struct
        call print_duration            ; rax = secs since boot

        print newline, 1
        ret

; out: `procs: 0`
print_procs:
        print procs_label, procs_label_len

        mov rax, qword [sysinfo_buf + SYS_PROCS]

        mov rdi, itoa_buf
        call itoa
        mov rdi, rsi
        call print_str

        print newline, 1
        ret

; out: `ram: 17/31 GiB`
print_ram:
        print ram_label, ram_label_len

        mov rbx, qword [sysinfo_buf + SYS_RAM_TOTAL]
        mov rax, rbx                   ; keep for later
        sub rax, qword [sysinfo_buf + SYS_RAM_FREE]
        sub rax, qword [sysinfo_buf + SYS_RAM_BUFFER]

        shr rax, 30                    ; rax = used GiB (div 2^30 with shift right)

        push rbx                       ; save total bytes

        mov rdi, itoa_buf
        call itoa
        mov rdi, rsi
        call print_str

        print slash, 1

        pop rax
        shr rax, 30                    ; rax = total GiB (div 2^30 with shift right)

        mov rdi, itoa_buf
        call itoa
        mov rdi, rsi
        call print_str

        print gb_suffix, gb_suffix_len
        print newline, 1
        ret

; out: `swap: 8/49 GiB` (no idea why I have so much swap rofl)
print_swap:
        print swap_label, swap_label_len

        mov rbx, qword [sysinfo_buf + SYS_SWAP_TOTAL]
        mov rax, rbx                   ; keep for later
        sub rax, qword [sysinfo_buf + SYS_SWAP_FREE]

        mov rcx, 1073741824            ; 1 GiB in bytes
        xor rdx, rdx
        div rcx                        ; rax = used GiB

        push rcx                       ; save divisor
        push rbx                       ; save total bytes

        mov rdi, itoa_buf
        call itoa
        mov rdi, rsi
        call print_str

        print slash, 1

        pop rax                        ; rax = total bytes
        pop rcx                        ; rcx = divisor
        xor rdx, rdx
        div rcx                        ; rax = total GiB

        mov rdi, itoa_buf
        call itoa
        mov rdi, rsi
        call print_str

        print gb_suffix, gb_suffix_len
        print newline, 1
        ret

