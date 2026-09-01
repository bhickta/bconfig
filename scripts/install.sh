#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

case "${1:-}" in
  --update)
    if [ "$#" -ne 1 ]; then
      printf 'usage: %s [--update]\n' "$0" >&2
      exit 2
    fi
    exec "${repo_root}/scripts/update.sh"
    ;;
  "")
    ;;
  *)
    printf 'usage: %s [--update]\n' "$0" >&2
    exit 2
    ;;
esac

"${repo_root}/scripts/install-editors.sh"
"${repo_root}/scripts/verify.sh"
