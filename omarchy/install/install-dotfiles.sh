#!/usr/bin/env bash

REPO_URL="git@github.com:trucke/dotfiles-v2.git"
DOTFILES="${HOME}/.dotfiles"

is_stow_installed() {
	pacman -Qi "stow" &>/dev/null
}

if ! is_stow_installed; then
	echo "Install stow first"
	exit 1
fi

pushd ~ >/dev/null

# Check if the repository already exists
if [ -d "${DOTFILES}" ]; then
	echo "Repository '${DOTFILES}' already exists. Skipping clone."
else
	git clone "${REPO_URL}" "${DOTFILES}" || {
		echo "Failed to clone the repository."
		exit 1
	}
fi

echo "Removing old configs"
rm -rf ~/.config/nvim \
	~/.config/starship.toml \
	~/.local/share/nvim/ \
	~/.cache/nvim/ \
	~/.config/ghostty/config \
	~/.config/git \
	~/.config/mise \
	~/.config/kanshi \
	~/.config/kanata \
	~/.config/waybar

echo "Link personal config files"
stow --restow --dir="${DOTFILES}/omarchy" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}" zshrc
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.local/bin" bin

popd >/dev/null

omarchy-restart-waybar
omarchy-restart-terminal >/dev/null

echo "Dotfiles successfully installed."
