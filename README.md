# git2.nvim

[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/Freed-Wu/git2.nvim/main.svg)](https://results.pre-commit.ci/latest/github/Freed-Wu/git2.nvim/main)
[![github/workflow](https://github.com/Freed-Wu/git2.nvim/actions/workflows/main.yml/badge.svg)](https://github.com/Freed-Wu/git2.nvim/actions)

[![github/downloads](https://shields.io/github/downloads/Freed-Wu/git2.nvim/total)](https://github.com/Freed-Wu/git2.nvim/releases)
[![github/downloads/latest](https://shields.io/github/downloads/Freed-Wu/git2.nvim/latest/total)](https://github.com/Freed-Wu/git2.nvim/releases/latest)
[![github/issues](https://shields.io/github/issues/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/issues)
[![github/issues-closed](https://shields.io/github/issues-closed/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/issues?q=is%3Aissue+is%3Aclosed)
[![github/issues-pr](https://shields.io/github/issues-pr/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/pulls)
[![github/issues-pr-closed](https://shields.io/github/issues-pr-closed/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/pulls?q=is%3Apr+is%3Aclosed)
[![github/discussions](https://shields.io/github/discussions/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/discussions)
[![github/milestones](https://shields.io/github/milestones/all/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/milestones)
[![github/forks](https://shields.io/github/forks/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/network/members)
[![github/stars](https://shields.io/github/stars/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/stargazers)
[![github/watchers](https://shields.io/github/watchers/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/watchers)
[![github/contributors](https://shields.io/github/contributors/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/graphs/contributors)
[![github/commit-activity](https://shields.io/github/commit-activity/w/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/graphs/commit-activity)
[![github/last-commit](https://shields.io/github/last-commit/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/commits)
[![github/release-date](https://shields.io/github/release-date/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/releases/latest)

[![github/license](https://shields.io/github/license/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim/blob/main/LICENSE)
[![github/languages](https://shields.io/github/languages/count/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim)
[![github/languages/top](https://shields.io/github/languages/top/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim)
[![github/directory-file-count](https://shields.io/github/directory-file-count/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim)
[![github/code-size](https://shields.io/github/languages/code-size/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim)
[![github/repo-size](https://shields.io/github/repo-size/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim)
[![github/v](https://shields.io/github/v/release/Freed-Wu/git2.nvim)](https://github.com/Freed-Wu/git2.nvim)

[![luarocks](https://img.shields.io/luarocks/v/Freed-Wu/git2.nvim)](https://luarocks.org/modules/Freed-Wu/git2.nvim)

Use [luagit2](https://github.com/libgit2/luagit2) to realize a `:Git` in neovim.

## Related Projects

### CLI

- [vim-fugitive](https://github.com/tpope/vim-fugitive): call git process
  **synchronously**. written in vim script.
- [vim-gina](https://github.com/lambdalisue/vim-gina): call git process
  asynchronously. written in vim script. **stop maintenance**.
- [vim-gin](https://github.com/lambdalisue/vim-gin): call git process
  asynchronously. written in denojs. same author as vim-gina.
- [git.nvim](https://github.com/wsdjeg/git.nvim): call git process
  asynchronously. written in lua.

### UI

- [vim-flog](https://github.com/rbong/vim-flog): call git process
  **synchronously**. written in vim script.
- [committia.vim](https://github.com/rhysd/committia.vim): UI for CLI's
  `git commit`. call git process **synchronously**. written in vim script.
- [nvim-tinygit](https://github.com/chrisgrieser/nvim-tinygit): call git process
  asynchronously. written in lua.
- [neogit](https://github.com/NeogitOrg/neogit): call git process
  asynchronously. written in lua.
- [blame.nvim](https://github.com/FabijanZulj/blame.nvim): UI for `git blame`.
  call git process asynchronously. written in lua. inspired fugit2.nvim's
  `Fugit2Blame`
- [fugit2.nvim](https://github.com/SuperBo/fugit2.nvim): call libgit2 by luajit
  FFI. written in lua.

### Plugin

- [coc-git](https://github.com/neoclide/coc-git): call git process
  asynchronously.
  [issue about libgit2](https://github.com/neoclide/coc-git/issues/216)
- [fern-git-status.vim](http://github.com/lambdalisue/fern-git-status.vim): call
  git process synchronously.
- [fern-mapping-git.vim](http://github.com/lambdalisue/fern-mapping-git.vim): call
  git process synchronously.

## Similar Projects

- [magit](https://github.com/magit/magit): git UI for emacs

## Motivation

- Many vim users are experienced CLI users, a vim command `:Git` like CLI's
  `git` should be helpful to save their learning time. A good CLI even is a more
  significant matter than UI. In this aspect, vim-fugitive, vim-gina do well.
- call git process synchronously is slow. many vim plugins select use vim
  script's `jobstart()` or neovim's `vim.uv.timer` to call git process
  asynchronously. fugit2.nvim is 1st plugin to call libgit2 and bring novelty to
  vim community. Don't call git process can avoid some
  [bug](https://github.com/rhysd/committia.vim/issues/66) of incorrect shell
  settings. On Oct 2024, official lua binding of libgit2
  [lua-git2](https://luarocks.org/modules/neopallium/lua-git2) is released
  firstly. I believe it can bring more convenience to vim plugin developing and
  start the experiment.

## Dependence

- [libgit2](https://github.com/libgit2/libgit2)

```sh
# Ubuntu
sudo apt-get -y install libgit2-dev libgit2
sudo apt-mark auto libgit2-dev
# ArchLinux
sudo pacman -S libgit2
# Android Termux
apt-get -y install libgit2
# Nix
# use nix-shell to create a virtual environment then build
# homebrew
brew tap tonyfettes/homebrew-git2
brew install libgit2 pkg-config
# Windows msys2
pacboy -S --noconfirm pkg-config libgit2 gcc
```

## Install

### rocks.nvim

#### Command style

```vim
:Rocks install git2.nvim
```

#### Declare style

`~/.config/nvim/rocks.toml`:

```toml
[plugins]
"git2.nvim" = "scm"
```

Then

```vim
:Rocks sync
```

or:

```sh
$ luarocks --lua-version 5.1 --local --tree ~/.local/share/nvim/rocks install git2.nvim
# ~/.local/share/nvim/rocks is the default rocks tree path
# you can change it according to your vim.g.rocks_nvim.rocks_path
```

### lazy.nvim

```lua
require("lazy").setup {
  spec = {
    { "Freed-Wu/git2.nvim", lazy = false },
  },
}
```

## Usage

```vim
:edit subdir/test.txt
:Git init
:cd subdir
:Git -C .. add %
:Git rm --cached %
```

## TODO

- full CLI APIs. wait [upstream](https://github.com/libgit2/luagit2/issues/10)
- UI for CLI's `git commit`, vim's `:Git blame`, `:Git status`, ...
