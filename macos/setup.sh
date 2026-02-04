#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${HOME}/.dotfiles"

mkdir -p "${HOME}/.config"
mkdir -p "${HOME}/.local/bin"
mkdir -p "${HOME}/development"

bash "${DOTFILES}/macos/scripts/privacy-script.sh"
source "${DOTFILES}/macos/scripts/settings.sh"

# Rosetta 2 is needed for some of the applications installed later on
sudo softwareupdate --install-rosetta --agree-to-license

# install homebrew if not present
if ! command -v /opt/homebrew/bin/brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# make environment settings available for brew
source "${DOTFILES}/share/shell/env"

/opt/homebrew/bin/brew bundle --file "${DOTFILES}/macos/Brewfile" --no-lock

stow --restow --dir="${DOTFILES}/share" --target="${HOME}" zshrc
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.local/bin" bin

# install dev tools via mise
mise install
