# bconfig

Personal Linux configuration repo for keeping machines in sync.

## Layout

- `nvim/bvim/` - Bhickta Neovim configuration, launched with `bvim`
- `inspiration/` - ignored local inspiration/reference checkouts
- `scripts/` - local install and sync helpers
- `symlink-setup.sh` - dotfile symlink entrypoint, following the classic dotfiles repo pattern

## Setup

Run from the repo root:

```sh
./scripts/install-editors.sh
```

This installs:

- `avim` - AstroNvim template config at `~/.config/avim`
- `bvim` - this repo's Neovim config at `~/.config/bvim`
- `nvim` - the normal/default Neovim command, with no config managed by this repo

To only refresh managed dotfile links:

```sh
./symlink-setup.sh
```

If a real file or directory already exists at a target path, the script refuses to replace it unless `BCONFIG_FORCE=1` is set.

## Inspiration

Ignored local reference checkouts:

- `inspiration/AstroNvim/` from `git@github.com:AstroNvim/AstroNvim.git`
- `inspiration/paulirish-dotfiles/` from `https://github.com/paulirish/dotfiles.git`
