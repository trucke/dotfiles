#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="${HOME}/.dotfiles/loki/install"

# Repo packages via pacman, AUR via yay — both through omarchy pkg, which is
# idempotent (skips present) and verifies each package actually installed.
# Comments (#) and blank lines in the lists are ignored.
mapfile -t repo_pkgs < <(grep -vE '^\s*(#|$)' "${INSTALL_DIR}/packages.repo")
mapfile -t aur_pkgs  < <(grep -vE '^\s*(#|$)' "${INSTALL_DIR}/packages.aur")

omarchy pkg add "${repo_pkgs[@]}"
omarchy pkg aur add "${aur_pkgs[@]}"

# NOTE: `mise install` lives in loki/sync.sh — it must run AFTER the mise config
# is stowed, which happens during dotfiles deployment (this runs before that).

echo "Packages installed."
