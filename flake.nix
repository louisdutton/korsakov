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
          default = mkShell {
            nativeBuildInputs = [
              odin
            ];

            buildInputs = [
              tree-sitter
              tree-sitter-grammars.tree-sitter-c
            ];

            packages = [
              gdb
              ols
              nixd
              alejandra
            ];

            TS_GRAMMARS = "${tree-sitter-grammars.tree-sitter-c}";
          };
        }
    );
  };
}
