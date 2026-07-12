#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="${HOME}/.dotfiles/loki/install"

# Comments (#) and blank lines in the lists are ignored.
mapfile -t repo_pkgs < <(grep -vE '^\s*(#|$)' "${INSTALL_DIR}/packages.repo")
mapfile -t aur_pkgs < <(grep -vE '^\s*(#|$)' "${INSTALL_DIR}/packages.aur")

omarchy pkg add "${repo_pkgs[@]}"

# opencode-bin conflicts with Omarchy's preinstalled opencode package.
omarchy pkg drop opencode

yay -S --noconfirm --needed "${aur_pkgs[@]}"

for target in "${aur_pkgs[@]}"; do
	pacman -Q "${target#aur/}" >/dev/null
done

# NOTE: `mise install` lives in loki/sync.sh — it must run AFTER the mise config
# is stowed, which happens during dotfiles deployment (this runs before that).

echo "Packages installed."
