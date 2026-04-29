{
  description = "fasmfetch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    asm-lsp = {
      url = "github:bergercookie/asm-lsp/master";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, asm-lsp, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} =
        let
          fasmfetch = pkgs.stdenv.mkDerivation {
            pname = "fasmfetch";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = [ pkgs.fasm ];

            buildPhase = ''
              fasm main.S fasmfetch
            '';

            installPhase = ''
              mkdir -p $out/bin
              install -m755 fasmfetch $out/bin/fasmfetch
              ln --symbolic $out/bin/fasmfetch $out/bin/ff
            '';
          };
        in
        {
          inherit fasmfetch;
          default = fasmfetch;
        };

      devShells.${system} =
        let
          asm-lsp-master = pkgs.rustPlatform.buildRustPackage {
            pname = "asm-lsp";
            version = "master";
            src = asm-lsp;
            cargoHash = "sha256-D91n+sx8qwkn/rEWP5ftS/mhmRru43TmKZUyvAc47H0=";
            nativeBuildInputs = [ pkgs.pkg-config ];
            buildInputs = [ pkgs.openssl ];
            doCheck = false;
          };
        in
        {
          default = pkgs.mkShell {
            buildInputs = [
              # fasm
              asm-lsp-master
              pkgs.gcc
              pkgs.gdb
              pkgs.fasm

              # task runner
              pkgs.just
              pkgs.nushell

              # benchmarks
              pkgs.fastfetch
              pkgs.hyperfine
            ];
          };
        };
    };
}
