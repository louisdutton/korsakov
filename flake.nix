{
  description = "Korsakov text editor - Odin development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          }
      );
  in {
    devShells = forEachSupportedSystem (
      {pkgs}:
        with pkgs; {
          default = let
            tree-sitter-odin = tree-sitter.buildGrammar rec {
              language = "odin";
              version = "1.3.0";
              src = fetchFromGitHub {
                owner = "tree-sitter-grammars";
                repo = "tree-sitter-odin";
                rev = "v${version}";
                hash = "sha256-vlw5XaHTdsgO9H4y8z0u0faYzs+L3UZPhqhD/IJ6khY=";
              };
            };
          in
            mkShell {
              nativeBuildInputs = [
                odin
              ];

              buildInputs = [
                tree-sitter
                tree-sitter-odin
              ];

              packages = [
                gdb
                ols
                nixd
                alejandra
              ];

              TS_GRAMMARS = "${tree-sitter-odin}";
            };
        }
    );
  };
}
