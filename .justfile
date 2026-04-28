set shell := [ "nu", "--commands" ]

TARGET := "./target"
NAME := "fasmfetch"
OUT := "{{TARGET}}/{{NAME}}"

alias b := build
alias c := clean
alias d := disasm
alias i := info
alias r := run
alias w := watch

[private]
@default:
    just --list

@build:
    mkdir ./{{TARGET}}
    fasm main.asm {{OUT}}

@run: build
    {{OUT}}

@clean:
    rm --force *.bin *.o {{TARGET}}/*;

@disasm: build
    objdump --disassemble-all --source {{OUT}}

@info: build
    file {{OUT}}
    readelf --file-header {{OUT}}

@watch:
    %watch main.s { just run }
