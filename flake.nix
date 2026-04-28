{
  description = "fasmfetch";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
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

      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.asm-lsp
            pkgs.gcc
            pkgs.gdb
            pkgs.fasm
            pkgs.just
            pkgs.nushell
          ];
        };
      });
    };
}
