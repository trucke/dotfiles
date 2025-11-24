#!/usr/bin/env bash

ORIGINAL_DIR=$(pwd)
REPO_URL="github.com:trucke/dotfiles-v2"
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
cd "${DOTFILES}"
stow --restow --dir="${DOTFILES}/omarchy" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}" zshrc

popd >/dev/null

omarchy-restart-waybar
omarchy-restart-terminal >/dev/null

echo "Dotfiles successfully installed."
