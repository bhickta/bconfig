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

After cloning this repo on another PC, run:

```sh
./scripts/install.sh
```

If a managed path already contains a local file or directory, the installer moves it to a timestamped directory under `~/.local/state/bconfig/backups/` before creating the link. To explicitly replace conflicts without making backups:

```sh
BCONFIG_FORCE=1 ./scripts/install.sh
```

Codex authentication, logs, history, sessions, caches, and SQLite state are intentionally not tracked. Sign in to Codex separately on each PC.

## Updating another PC

Commit and push changes from the source PC first. Then run this from the checkout on every other PC:

```sh
./scripts/install.sh --update
```

The update command:

- refuses to overwrite uncommitted tracked changes
- pulls the current branch with `--ff-only`
- refreshes all managed symlinks and launchers
- restores bvim and avim plugins to the commits in their `lazy-lock.json` files
- verifies that bvim loaded the managed commands and shortcuts, including `Ctrl+<` and `Ctrl+>`

Only committed and pushed files in this repository are synchronized. Credentials, editor history, caches, notes, and other machine-local state remain local. Set `UPSC_NOTES_VAULT` on a machine only when its notes directory is not `~/development/upsc`.

### Reading a folder as one document

In bvim, focus a folder in Neo-tree with `.`, then use `Space m r` to combine its `.md` files into one read-only reading view. You can also press `g r` in Neo-tree or use `:ReadFolder [path]`. Markdown files in subfolders are included recursively; repository and trash metadata folders are skipped.

The document hierarchy follows the directory tree: `# current folder`, `## subfolder`, `### filename.md`, then that note's headings nested beneath it. Root-level notes are `## filename.md`, and deeper subfolders add another heading level. Only each file or folder's name is displayed, not its full path. Markdown-looking text inside fenced code blocks is preserved exactly; levels are capped at Markdown's `######` limit.

Inside the combined view, use `] f` / `[ f` for the next or previous note, `g f` to open the source note at the corresponding line, `R` to refresh, and `q` to close. Files remain separate on disk; the combined buffer is only a reading view.

Folder View remembers the last focused note, position within that note, and cursor column for each folder. The position is restored after closing the view or restarting bvim, and remains accurate when earlier notes change length. This cursor history is machine-local and is not synchronized by the repository.

Dashboard `o` and `Space f o` keep the normal recent-file results and also list recent Folder Views. Selecting one regenerates the combined view and restores its saved cursor position.

The combined view supports the normal Markdown reading features, including rendered Markdown, total/remaining reading time, reading-speed controls, auto-scroll, block focus, selection translation, zen mode, and explorer split navigation. It stays read-only; use `g f` before editing source content.

Auto-scroll starts at the current cursor position. Use `Space r a` to start it, pause without losing your place, and resume from the same line. The statusline shows `▶` while it is running and `⏸` while paused.

Block focus preserves context for nested points: when the cursor is on a child or deeper item, its top-level parent branch and descendants remain focused together.

The bottom-right statusline shows `Ln current/total Col column`, so the total number of lines remains visible in normal notes and combined folder views.

File scrolling keeps the cursor line about 20% from the top of the window whenever the document has enough preceding lines. Neo-tree retains normal list scrolling.

For an offline relink that does not restore plugins, use:

```sh
BCONFIG_SKIP_PLUGIN_RESTORE=1 ./scripts/install.sh
```

To only refresh managed dotfile links:

```sh
./symlink-setup.sh
```

Missing optional source files (currently `codex/AGENTS.md`) are skipped, so removing one from the repository also removes a symlink previously created for it.

## Inspiration

Ignored local reference checkouts:

- `inspiration/AstroNvim/` from `git@github.com:AstroNvim/AstroNvim.git`
- `inspiration/paulirish-dotfiles/` from `https://github.com/paulirish/dotfiles.git`
