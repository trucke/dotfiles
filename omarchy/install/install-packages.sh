#!/usr/bin/env bash

# Remove packages that conflict with ones we're about to install
echo "Removing conflicting packages..."
mapfile -t cleanup_packages <"$HOME/.dotfiles/omarchy/install/cleanup.packages"
for package in "${cleanup_packages[@]}"; do
	yay -Rnsu --noconfirm "$package" &>/dev/null
done
echo "Done."

mapfile -t packages <"$HOME/.dotfiles/omarchy/install/install.packages"

yay -Syu --noconfirm
for package in "${packages[@]}"; do
	yay -S --noconfirm --needed "$package"
done
