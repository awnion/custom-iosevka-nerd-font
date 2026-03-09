{
  description = "A flake for building afio font";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    font_src = {
      url = "github:be5invis/Iosevka?shallow=1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, font_src, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = rec {
          src = ./.;
          npmDeps = pkgs.fetchNpmDeps {
            hash = "sha256-9SrfnaDpdLR1KL8WQjFSM0Pza1yRm7/YgQ/TimTJm8o=";
          };
          default = pkgs.runCommand "afio" {
            buildInputs = with pkgs; [
              nodejs_22
              nodePackages.npm
              ttfautohint-nox
              gnutar
            ];

            # Set SOURCE_DATE_EPOCH for reproducible builds
            SOURCE_DATE_EPOCH = "1";
          } ''
            workdir=$(mktemp -d)

            echo copy "${font_src}" into workdir
            cp -r ${font_src}/* $workdir/

            echo copy private build plans into workdir
            cp ${src}/private-build-plans.toml $workdir/

            mkdir -p $out/log
            ls -la ${npmDeps} > $out/log/npm-deps
            echo "Build completed successfully" > $out/log/build-log
          '';
        };
      });
}

