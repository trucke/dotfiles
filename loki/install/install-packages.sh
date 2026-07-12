#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="${HOME}/.dotfiles/loki/install"
STATE_DIR="${HOME}/.local/state/dotfiles"
AGENT_AUR_MARKER="${STATE_DIR}/agent-aur-v1"

# Comments (#) and blank lines in the lists are ignored.
mapfile -t repo_pkgs < <(grep -vE '^\s*(#|$)' "${INSTALL_DIR}/packages.repo")
mapfile -t aur_pkgs < <(grep -vE '^\s*(#|$)' "${INSTALL_DIR}/packages.aur")

# Repo packages converge through Omarchy's idempotent wrapper.
omarchy pkg add "${repo_pkgs[@]}"

# Omarchy preinstalls same-named repo builds. pacman does not retain repository
# origin, so remove them exactly once before installing explicit AUR targets.
# opencode is always safe to drop: the desired package is named opencode-bin.
mkdir -p "${STATE_DIR}"
omarchy pkg drop opencode
if [ ! -e "${AGENT_AUR_MARKER}" ]; then
	omarchy pkg drop claude-code openai-codex-bin
fi

# Prefix every target so yay cannot silently select a same-named Omarchy package.
aur_targets=()
for pkg in "${aur_pkgs[@]}"; do
	aur_targets+=("aur/${pkg}")
done
yay -S --noconfirm --needed "${aur_targets[@]}"

# Verify registration before recording the one-time source migration.
for pkg in "${aur_pkgs[@]}"; do
	pacman -Q "${pkg}" >/dev/null
done
touch "${AGENT_AUR_MARKER}"

# NOTE: `mise install` lives in loki/sync.sh — it must run AFTER the mise config
# is stowed, which happens during dotfiles deployment (this runs before that).

echo "Packages installed."
