#!/usr/bin/env bash

mapfile -t packages < "$HOME/.dotfiles/omarchy/install/cleanup.packages"
for package in "${packages[@]}"; do
    yay -Rnsu --noconfirm "$package"
done

################################################################################

rm -rf ~/Work ~/go ~/.cargo ~/.npm

rm ~/.XCompose
rm .bash_history .bash_logout .bash_profile

rm -rf ~/.config/{Typora,xournalpp,lazygit}

################################################################################
