{ pkgs ? import (fetchTarball
  "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") { } }:

let inherit (pkgs) mkShell;
in mkShell {
  buildInputs = with pkgs; [
    nodejs
    nodePackages.npm
    ttfautohint-nox
    gnutar
    git
  ];

  shellHook = ''
    git clone --depth 1 https://github.com/be5invis/Iosevka iosevka
  '';
}
