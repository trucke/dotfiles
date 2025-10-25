#!/usr/bin/env bash

mkdir -p "${HOME}/development/projects"
mkdir -p "${HOME}/development/tools"
mkdir "${HOME}/.config"

pushd "${HOME}/.dotfiles"
source "./macos/scripts/privacy-script.sh"
source "./macos/scripts/settings.sh"
# Rosetta 2 is needed for some of the applications installed later on
sudo softwareupdate --install-rosetta --agree-to-license
/opt/homebrew/bin/brew bundle --file "./macos/Brewfile" --no-lock
stow --restow --dir="${DOTFILES}/share" --target="${HOME}" zshrc
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.local/bin" bin
popd

source "${HOME}/.zshrc"
