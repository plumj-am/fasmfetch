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
- [ ] uptime
- [ ] motherboard (host field in fastfetch)
- [ ] CPU name
- [ ] GPU
  - [ ] name
  - [ ] type (discrete/integrated)?
- [ ] RAM
  - [ ] name
  - [ ] usage?
- [ ] disk
  - [ ] name
  - [ ] usage?
- [ ] swap
  - [ ] name
  - [ ] usage?
- [ ] local IP?
- [ ] terminal font?
- [ ] system font?

I do not care about other features from fastfetch.

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
[7bb4ac5a75](https://github.com/plumj-am/fasmfetch/commit/7bb4ac5a75c21f7ebfa52a6de95324c2511162f7).

```
Benchmark 1: ./result/bin/fasmfetch
  Time (mean ± σ):     104.4 µs ±  19.5 µs    [User: 65.7 µs, System: 2.7 µs]
  Range (min … max):    90.7 µs … 212.0 µs    100 runs

Benchmark 2: fastfetch
  Time (mean ± σ):     191.8 ms ±  39.8 ms    [User: 70.3 ms, System: 39.8 ms]
  Range (min … max):   166.3 ms … 289.3 ms    100 runs

Summary
  ./result/bin/fasmfetch ran
 1836.71 ± 512.95 times faster than fastfetch
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
