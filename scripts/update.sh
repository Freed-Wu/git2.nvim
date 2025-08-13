#!/usr/bin/env bash
set -e
cd "$(dirname "$(dirname "$(readlink -f "$0")")")"

nix-shell --run 'luarocks install --force lua-git2 GIT2_INCDIR=$GIT2_INCDIR GIT2_LIBDIR=$GIT2_LIBDIR'
