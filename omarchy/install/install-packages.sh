#!/usr/bin/env bash

mapfile -t packages < "$HOME/.dotfiles/omarchy/install/install.packages"

yay -Syu --noconfirm
for package in "${packages[@]}"; do
    yay -S --noconfirm --needed "$package"
done
