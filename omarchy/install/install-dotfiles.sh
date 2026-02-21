#!/usr/bin/env bash

set -euo pipefail

REPO_URL="git@github.com:trucke/dotfiles-v2.git"
DOTFILES="${HOME}/.dotfiles"

if ! pacman -Qi "stow" &>/dev/null; then
	echo "Install stow first"
	exit 1
fi

pushd ~ >/dev/null

if [ -d "${DOTFILES}" ]; then
	echo "Repository '${DOTFILES}' already exists. Skipping clone."
else
	git clone "${REPO_URL}" "${DOTFILES}" || {
		echo "Failed to clone the repository."
		exit 1
	}
fi

echo "Removing old configs"
rm -rf "${HOME}/.config/nvim" \
	"${HOME}/.config/starship.toml" \
	"${HOME}/.local/share/nvim/" \
	"${HOME}/.cache/nvim/" \
	"${HOME}/.config/ghostty" \
	"${HOME}/.config/git" \
	"${HOME}/.config/mise" \
	"${HOME}/.config/kanshi" \
	"${HOME}/.config/kanata" \
	"${HOME}/.config/waybar"

# Remove Omarchy defaults that conflict with stowed dotfiles
rm -f "${HOME}/.config/opencode/opencode.json"
rm -f "${HOME}/.config/starship.toml"

mkdir -p "${HOME}/.local/bin"

echo "Link personal config files"
stow --restow --dir="${DOTFILES}/omarchy" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}" zshrc
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.local/bin" bin

popd >/dev/null

omarchy-restart-waybar
omarchy-restart-terminal >/dev/null

echo "Dotfiles successfully installed."
