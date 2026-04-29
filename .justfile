set shell := [ "nu", "--commands" ]

alias b := build
alias i := info
alias r := default
alias run := default
alias w := watch
alias be := bench

@default *args: build
    target/fasmfetch {{args}}

@build:
    mkdir target
    fasm main.S target/fasmfetch
    ln --symbolic --force fasmfetch target/ff

@info: build
    file target/fasmfetch
    readelf --file-header target/fasmfetch

@watch *args:
    watch main.S { just run {{args}} }

@bench:
    hyperfine --warmup=10 --runs=100 --shell=none "./target/fasmfetch" "fastfetch"
