set shell := [ "nu", "--commands" ]

alias b := build
alias c := clean
alias d := disasm
alias i := info
alias r := run
alias w := watch
alias be := bench

[private]
@default:
    just --list

@build:
    mkdir target
    fasm main.S target/fasmfetch
    ln --symbolic --force fasmfetch target/ff

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

@bench:
    hyperfine --warmup=10 --runs=100 --shell=none "./target/fasmfetch" "fastfetch"
