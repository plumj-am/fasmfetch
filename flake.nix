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
      inherit (nixpkgs.lib.attrsets) genAttrs;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = f: genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forEachSystem (
        pkgs:
        let
          fasmfetch = pkgs.stdenv.mkDerivation {
            pname = "fasmfetch";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = [ pkgs.fasm ];

            buildPhase = ''
              fasm main.s fasmfetch
            '';

            installPhase = ''
              mkdir -p $out/bin
              install -m755 fasmfetch $out/bin/fasmfetch
            '';
          };
        in
        {
          inherit fasmfetch;
          default = fasmfetch;
        }
      );

      devShells = forEachSystem (
        pkgs:
        let
          inherit asm-lsp;

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
              asm-lsp-master
              pkgs.gcc
              pkgs.gdb
              pkgs.fasm
              pkgs.just
              pkgs.nushell
            ];
          };
        }
      );
    };
}
