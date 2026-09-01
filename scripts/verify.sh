#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin_dir="${HOME}/.local/bin"

verify_link() {
  source_path=$1
  target_path=$2

  if [ ! -L "${target_path}" ] || [ "$(readlink "${target_path}")" != "${source_path}" ]; then
    printf 'error: %s is not linked to %s\n' "${target_path}" "${source_path}" >&2
    exit 1
  fi
}

verify_link "${repo_root}/nvim/nvim" "${HOME}/.config/nvim"
verify_link "${repo_root}/nvim/bvim" "${HOME}/.config/bvim"
verify_link "${repo_root}/nvim/avim" "${HOME}/.config/avim"
verify_link "${repo_root}/codex/config.toml" "${HOME}/.codex/config.toml"
verify_link "${repo_root}/codex/hooks.json" "${HOME}/.codex/hooks.json"
verify_link "${repo_root}/codex/rules" "${HOME}/.codex/rules"

if [ -e "${repo_root}/codex/AGENTS.md" ] || [ -L "${repo_root}/codex/AGENTS.md" ]; then
  verify_link "${repo_root}/codex/AGENTS.md" "${HOME}/.codex/AGENTS.md"
fi

if [ ! -x "${bin_dir}/bvim" ] || [ ! -x "${bin_dir}/avim" ]; then
  printf 'error: bvim and avim launchers were not installed in %s\n' "${bin_dir}" >&2
  exit 1
fi

env NVIM_APPNAME=bvim NVIM_NOTTYFAST=1 "${bin_dir}/bvim" --headless \
  "+luafile ${repo_root}/nvim/bvim/tests/installed_spec.lua" +qa

printf 'Verified managed links, editor launchers, commands, and shortcuts.\n'
