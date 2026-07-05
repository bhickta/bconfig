#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bin_dir="${HOME}/.local/bin"
nvim_bin="${bin_dir}/nvim"

if [ ! -x "${nvim_bin}" ]; then
  nvim_bin=$(command -v nvim)
fi

mkdir -p "${bin_dir}" "${HOME}/.config"

if [ -e "${HOME}/.config/nvim" ] && [ "$(readlink "${HOME}/.config/nvim" 2>/dev/null || true)" = "${repo_root}" ]; then
  rm "${HOME}/.config/nvim"
fi

"${repo_root}/symlink-setup.sh"

cat > "${bin_dir}/avim" <<EOF
#!/usr/bin/env sh
exec env NVIM_APPNAME=avim NVIM_NOTTYFAST=1 ${nvim_bin} "\$@"
EOF

cat > "${bin_dir}/bvim" <<EOF
#!/usr/bin/env sh
exec env NVIM_APPNAME=bvim NVIM_NOTTYFAST=1 ${nvim_bin} "\$@"
EOF

chmod +x "${bin_dir}/avim" "${bin_dir}/bvim"

printf 'Installed nvim -> %s\n' "${repo_root}/nvim/nvim"
printf 'Installed avim -> %s\n' "${repo_root}/nvim/avim"
printf 'Installed bvim -> %s\n' "${repo_root}/nvim/bvim"
printf 'Using nvim binary: %s\n' "${nvim_bin}"
