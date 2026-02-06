#!/usr/bin/env bash

echo "Run system cleanup..."

mapfile -t packages <"$HOME/.dotfiles/omarchy/install/cleanup.packages"
for package in "${packages[@]}"; do
	yay -Rnsu --noconfirm "$package" &>/dev/null
done

################################################################################

sudo rm -rf ~/Work ~/go ~/.cargo ~/.npm

rm -f ~/.XCompose
rm -f ~/.bash_history ~/.bash_logout ~/.bash_profile

rm -rf ~/.config/{Typora,xournalpp,lazygit}

################################################################################

echo "Cleanup finished."
