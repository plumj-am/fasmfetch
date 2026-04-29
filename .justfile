set shell := [ "nu", "--commands" ]

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
    mkdir target
    fasm main.S target/fasmfetch

@run *args: build
    target/fasmfetch {{args}}

@clean:
    rm --force *.bin *.o target/*;

@disasm: build
    objdump --disassemble-all --source target/fasmfetch

@info: build
    file target/fasmfetch
    readelf --file-header target/fasmfetch

@watch *args:
    watch main.S { just run {{args}} }
