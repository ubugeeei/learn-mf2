{
  description = "A type-driven Unicode MessageFormat 2 compiler in Idris 2";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [ idris2 gnumake jq zsh ];
            shellHook = ''
              echo "learn-mf2: Idris $(idris2 --version | cut -d' ' -f4)"
            '';
          };
        });

      checks = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          test = pkgs.runCommand "learn-mf2-test" {
            nativeBuildInputs = [ pkgs.idris2 pkgs.gnumake pkgs.zsh ];
          } ''
            cp -R ${self} source
            chmod -R u+w source
            cd source
            make check
            touch $out
          '';
        });
    };
}
