#!/usr/bin/env bash

mkdir "${HOME}/.config"

pushd "${HOME}/.dotfiles"

bash "./macos/privacy.sh"
bash "./macos/settings.sh"

if [[ "$(uname -p)" == "arm" && "$(uname)" == "Darwin" ]]; then
    # Rosetta 2 is needed for some of the applications installed later on
    sudo softwareupdate --install-rosetta --agree-to-license
    /opt/homebrew/bin/brew bundle --file "./Brewfile" --no-lock
else
    /usr/local/bin/brew bundle --file "./Brewfile" --no-lock
fi

stow ghostty git nvim ripgrep scripts starship tmux zshrc mise
source "${HOME}/.zshrc"

popd

mkdir -p "${HOME}/development/projects"
mkdir -p "${HOME}/development/tools"

git clone https://github.com/tmux-plugins/tpm "${HOME}/.local/share/tmux/plugins/tpm"
bash "${HOME}/.local/share/tmux/plugins/tpm/bin/install_plugins"
source "${HOME}/.zshrc"
