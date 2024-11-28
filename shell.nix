{ pkgs ? import <nixpkgs> { } }:

with pkgs;
mkShell {
  name = "tellenc.nvim";
  buildInputs = [
    pkg-config
    stdenv.cc
    luajit
    libgit2.dev
  ];
}
