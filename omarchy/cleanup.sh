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

rm -rf ~/.config/{Typora,xournalpp,lazygit,fcitx5}
rm -f ~/.config/environment.d/fcitx.conf

# Remove fcitx5 autostart from upstream Omarchy config
sed -i '/fcitx5/d' ~/.local/share/omarchy/default/hypr/autostart.conf 2>/dev/null

################################################################################

echo "Cleanup finished."
