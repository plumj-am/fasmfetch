# fasmfetch

Like fastfetch but a little bit faster. Written in flat assembler (fasm).

## Progress

- [ ] ASCII art
- [ ] username@~~hostname~~
- [ ] OS
- [x] kernel+version
- [ ] shell name
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
> Currently only x86_64-linux is supported.

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

```
Benchmark 1: ./target/fasmfetch
  Time (mean ± σ):     181.1 µs ±  91.8 µs    [User: 103.8 µs, System: 18.6 µs]
  Range (min … max):   111.6 µs … 981.6 µs    100000 runs
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
