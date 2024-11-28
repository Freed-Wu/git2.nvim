#!/usr/bin/env bash
set -e
cd "$(dirname "$(dirname "$(readlink -f "$0")")")"

nix-shell --run 'luarocks install --lua-version 5.1 --force --local lua-git2 GIT2_INCDIR=$(pkg-config --variable=includedir libgit2) GIT2_LIBDIR=$(pkg-config --variable=libdir libgit2)'
