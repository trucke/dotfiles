#!/usr/bin/env bash

set -euo pipefail

DOTFILES="${HOME}/.dotfiles"

if ! pacman -Qi "stow" &>/dev/null; then
	echo "Install stow first"
	exit 1
fi

# Fresh-only: remove Omarchy default configs that would block stow symlinks.
# (Not idempotent — would wipe editor state on re-run — so it lives here, not sync.sh.)
echo "Removing conflicting default configs"
rm -rf "${HOME}/.config/nvim" \
	"${HOME}/.local/share/nvim/" \
	"${HOME}/.cache/nvim/" \
	"${HOME}/.config/ghostty" \
	"${HOME}/.config/git" \
	"${HOME}/.config/mise" \
	"${HOME}/.config/tmux" \
	"${HOME}/.config/kanata"
rm -f "${HOME}/.config/starship.toml" \
	"${HOME}/.config/opencode/opencode.json" \
	"${HOME}/.config/zed/settings.json" \
	"${HOME}/.config/zed/keymap.json"

# Everything else (stow, submodules, hypr overrides, ...) is idempotent.
bash "${DOTFILES}/loki/sync.sh"

echo "Dotfiles successfully installed."
