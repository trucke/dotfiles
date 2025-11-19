#!/usr/bin/env bash

ORIGINAL_DIR=$(pwd)
REPO_URL="github.com:trucke/dotfiles-v2"
DOTFILES=".dotfiles"

is_stow_installed() {
    pacman -Qi "stow" &>/dev/null
}

if ! is_stow_installed; then
    echo "Install stow first"
    exit 1
fi

pushd ~

# Check if the repository already exists
if [ -d "$DOTFILES" ]; then
    echo "Repository '$DOTFILES' already exists. Skipping clone"
else
    git clone "$REPO_URL" "$DOTFILES" || {
        echo "Failed to clone the repository."
        exit 1
    }
    echo "removing old configs"
    rm -rf ~/.config/nvim \
        ~/.config/starship.toml \
        ~/.local/share/nvim/ \
        ~/.cache/nvim/ \
        ~/.config/ghostty/config \
        ~/.config/git \
        ~/.config/mise \
        ~/.config/kanshi
fi

echo "Link personal config files"
cd "$HOME/${DOTFILES}"
stow --restow --dir="${DOTFILES}/omarchy/config" --target="${HOME}/.config" waybar
stow --restow --dir="${DOTFILES}/omarchy/config" --target="${HOME}/.config" kanshi
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}" zshrc

popd

omarchy-restart-waybar
