# fasmfetch

Like fastfetch but a little bit faster. Written in flat assembler (fasm).

## Progress

- [ ] ASCII art
- [x] username@hostname
- [ ] OS
- [x] kernel+version
- [x] shell name
- [x] terminal name
- [ ] displays
- [x] uptime
- [x] total process count
- [ ] motherboard (host field in fastfetch)
- [ ] CPU name
- [ ] GPU name (handle many? seems a pain)
- [x] RAM usage
- [ ] disk usage
- [x] swap usage
- [ ] local IP?
- [ ] terminal font?
- [ ] system font?
- [x] color swatches

Items suffixed with ? are maybes.

fasmfetch will not be configurable, apart from maybe a couple of flags.

## Usage

> [!WARNING]
> Only x86_64-linux is supported.

### Nix

```bash
nix run github:plumj-am/fasmfetch
```

Or add this flake as an input and add fasmfetch to your packages.

```nix
# flake.nix
{
  inputs.fasmfetch = {
    url = "github:plumj-am/fasmfetch";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}

# packages.nix
let
  fasmfetch = inputs.fasmfetch.packages.${pkgs.stdenv.hostPlatform.system}.default
in
{
  environment.systemPackages = [ fasmfetch ];
}
```

### From source

You will, at the very least, need the
[flat assembler](https://flatassembler.net). If you use Nix, you can use the
provided devshell which includes all the necessary dependencies and more.

```bash
git clone https://git.plumj.am/plumjam/fasmfetch

cd fasmfetch

just run
# or
fasm main.S target/fasmfetch
./target/fasmfetch
```

## Performance

It's difficult to get rid of outliers, even with warmup. I'm not yet sure why.

Benchmarked with [Hyperfine](https://github.com/sharkdp/hyperfine) on commit
[b6cc005b16](https://github.com/plumj-am/fasmfetch/commit/b6cc005b16ea67b026d99dbd868235cc1cd49c2e).

```
Benchmark 1: ./result/bin/fasmfetch
  Time (mean ± σ):     106.4 µs ±  10.7 µs    [User: 66.9 µs, System: 4.1 µs]
  Range (min … max):    93.5 µs … 144.1 µs    100 runs

Benchmark 2: fastfetch
  Time (mean ± σ):     195.9 ms ±  40.0 ms    [User: 70.5 ms, System: 38.2 ms]
  Range (min … max):   172.4 ms … 290.2 ms    100 runs

Summary
  ./result/bin/fasmfetch ran
 1842.08 ± 419.05 times faster than fastfetch
```

I will keep this updated as I extend the program.

## License

```
The MIT License (MIT)

Copyright (c) 2026-present PlumJam <git@plumj.am>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
