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

  outputs = { self, nixpkgs, flake-utils, font_src, ... }@inputs: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages = rec {
        default = pkgs.stdenv.mkDerivation {
          name = "afio";
          buildInputs = with pkgs; [
            # qt5.qmake
            # qt5.qtbase
            curl
            cacert
            ttfautohint-nox
            nodejs_22
            nodePackages.npm
            gnutar

            # nodePackages.pnpm
          ];

          src = font_src;

          buildPhase = ''
            cp -v ${./private-build-plans.toml} private-build-plans.toml
            npm install 2>&1 > /dev/null
            npm run build -- ttf::afio
          '';
          installPhase = ''
            mkdir -p $out/
            mkdir -p $out/share
            cp -r * $out/share/
            ls -la > $out/ls.txt
            # cp -avL dist/*/ttf/* $out
          '';
        };
      };
    });
}

