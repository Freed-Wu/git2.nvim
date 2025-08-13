{ pkgs ? import <nixpkgs> { } }:

with pkgs;
mkShell {
  name = "git2.nvim";
  env = {
    GIT2_INCDIR = "${libgit2.dev}/include";
    GIT2_LIBDIR = "${libgit2.lib}/lib";
  };
  buildInputs = [
    libgit2

    (luajit.withPackages (
      p: with p; [
        busted
        ldoc
      ]
    ))
  ];
}
