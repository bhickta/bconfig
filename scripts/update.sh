#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if ! git -C "${repo_root}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'error: %s is not a Git checkout\n' "${repo_root}" >&2
  exit 1
fi

if ! git -C "${repo_root}" diff --quiet || ! git -C "${repo_root}" diff --cached --quiet; then
  printf 'error: tracked files have local changes; commit, stash, or discard them before updating\n' >&2
  exit 1
fi

if ! git -C "${repo_root}" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
  printf 'error: the current branch has no upstream; configure one before updating\n' >&2
  exit 1
fi

printf 'Updating tracked configuration from the current branch upstream...\n'
git -C "${repo_root}" pull --ff-only

exec "${repo_root}/scripts/install.sh"
