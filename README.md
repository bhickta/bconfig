# bconfig

Personal Linux configuration repo for keeping machines in sync.

## Layout

- `codex/` - portable Codex CLI config, global instructions, hooks, and rules
- `nvim/nvim/` - synced plain Neovim config directory, intentionally no `init.lua`
- `nvim/bvim/` - Bhickta Neovim configuration, launched with `bvim`
- `nvim/avim/` - AstroNvim template configuration, launched with `avim`
- `inspiration/` - ignored local inspiration/reference checkouts
- `scripts/` - local install and sync helpers
- `symlink-setup.sh` - dotfile symlink entrypoint, following the classic dotfiles repo pattern

## Setup

Run from the repo root:

```sh
./scripts/install.sh
```

This installs and links:

- `avim` - AstroNvim template config at `~/.config/avim`
- `bvim` - this repo's Neovim config at `~/.config/bvim`
- `nvim` - the normal/default Neovim command, synced at `~/.config/nvim` without an `init.lua`
- `codex` - portable Codex config files under `~/.codex`

After pulling this repo on another PC, run:

```sh
./scripts/install.sh
```

If that PC already has local config files and you want this repo to replace them:

```sh
BCONFIG_FORCE=1 ./scripts/install.sh
```

Codex authentication, logs, history, sessions, caches, and SQLite state are intentionally not tracked. Sign in to Codex separately on each PC.
The tracked Codex config expects `headroom` and `tokensave` to be installed on `PATH` if you want the same MCP and hook behavior.

To only refresh managed dotfile links:

```sh
./symlink-setup.sh
```

If a real file or directory already exists at a target path, the script refuses to replace it unless `BCONFIG_FORCE=1` is set.

## Inspiration

Ignored local reference checkouts:

- `inspiration/AstroNvim/` from `git@github.com:AstroNvim/AstroNvim.git`
- `inspiration/paulirish-dotfiles/` from `https://github.com/paulirish/dotfiles.git`
