#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
backup_root="${BCONFIG_BACKUP_DIR:-${HOME}/.local/state/bconfig/backups/$(date '+%Y%m%d-%H%M%S')-$$}"

link_path() {
  source_path=$1
  target_path=$2
  target_dir=$(dirname -- "${target_path}")

  mkdir -p "${target_dir}"

  if [ ! -e "${source_path}" ] && [ ! -L "${source_path}" ]; then
    printf 'error: managed source is missing: %s\n' "${source_path}" >&2
    exit 1
  fi

  if [ -L "${target_path}" ] && [ "$(readlink "${target_path}")" = "${source_path}" ]; then
    printf 'ok %s -> %s\n' "${target_path}" "${source_path}"
    return
  fi

  if [ -e "${target_path}" ] || [ -L "${target_path}" ]; then
    if [ "${BCONFIG_FORCE:-0}" = "1" ]; then
      rm -rf "${target_path}"
    else
      relative_target=${target_path#"${HOME}"/}
      backup_path="${backup_root}/${relative_target}"
      mkdir -p "$(dirname -- "${backup_path}")"
      mv "${target_path}" "${backup_path}"
      printf 'backup %s -> %s\n' "${target_path}" "${backup_path}"
    fi
  fi

  ln -s "${source_path}" "${target_path}"
  printf 'link %s -> %s\n' "${target_path}" "${source_path}"
}

link_optional_path() {
  source_path=$1
  target_path=$2

  if [ ! -e "${source_path}" ] && [ ! -L "${source_path}" ]; then
    if [ -L "${target_path}" ] && [ "$(readlink "${target_path}")" = "${source_path}" ]; then
      rm "${target_path}"
      printf 'remove %s; optional managed source is absent\n' "${target_path}"
    else
      printf 'skip %s; optional managed source is absent\n' "${target_path}"
    fi
    return
  fi

  link_path "${source_path}" "${target_path}"
}

link_path "${repo_root}/nvim/nvim" "${HOME}/.config/nvim"
link_path "${repo_root}/nvim/bvim" "${HOME}/.config/bvim"
link_path "${repo_root}/nvim/avim" "${HOME}/.config/avim"

link_path "${repo_root}/codex/config.toml" "${HOME}/.codex/config.toml"
link_optional_path "${repo_root}/codex/AGENTS.md" "${HOME}/.codex/AGENTS.md"
link_path "${repo_root}/codex/hooks.json" "${HOME}/.codex/hooks.json"
link_path "${repo_root}/codex/rules" "${HOME}/.codex/rules"
