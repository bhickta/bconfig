#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

link_path() {
  source_path=$1
  target_path=$2
  target_dir=$(dirname -- "${target_path}")

  mkdir -p "${target_dir}"

  if [ -L "${target_path}" ] && [ "$(readlink "${target_path}")" = "${source_path}" ]; then
    printf 'ok %s -> %s\n' "${target_path}" "${source_path}"
    return
  fi

  if [ -e "${target_path}" ] || [ -L "${target_path}" ]; then
    if [ "${BCONFIG_FORCE:-0}" != "1" ]; then
      printf 'skip %s exists; rerun with BCONFIG_FORCE=1 to replace it\n' "${target_path}" >&2
      return 1
    fi

    rm -rf "${target_path}"
  fi

  ln -s "${source_path}" "${target_path}"
  printf 'link %s -> %s\n' "${target_path}" "${source_path}"
}

link_path "${repo_root}/nvim/nvim" "${HOME}/.config/nvim"
link_path "${repo_root}/nvim/bvim" "${HOME}/.config/bvim"
link_path "${repo_root}/nvim/avim" "${HOME}/.config/avim"
