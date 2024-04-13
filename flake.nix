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

            packages = [
              # terminal/ui libraries that might be needed
              ncurses

              # tree-sitter for syntax highlighting
              tree-sitter

              # debugging
              gdb
              lldb

              # language support
              ols
              nixd
              alejandra
            ];

            shellHook = ''
              echo "Korsakov Odin development environment ready!"
              echo "Odin version: $(odin version)"
            '';
          };
        }
    );
  };
}
