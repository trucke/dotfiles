#!/usr/bin/env bash

echo "Run system cleanup..."

mapfile -t packages <"$HOME/.dotfiles/omarchy/install/cleanup.packages"
for package in "${packages[@]}"; do
	yay -Rnsu --noconfirm "$package" &>/dev/null
done

################################################################################

rm -rf ~/Work ~/go ~/.cargo ~/.npm

rm -f ~/.XCompose
rm -f ~/.bash_history ~/.bash_logout ~/.bash_profile

rm -rf ~/.config/{Typora,xournalpp,lazygit}

# Remove Omarchy defaults that conflict with stowed dotfiles
rm -f ~/.config/opencode/opencode.json
rm -rf ~/.config/ghostty
rm -rf ~/.config/git
rm -f ~/.config/starship.toml

################################################################################

echo "Cleanup finished."
