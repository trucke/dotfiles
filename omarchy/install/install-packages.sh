#!/usr/bin/env bash

mapfile -t packages < "$HOME/supplement/install.packages"

yay -Syu
for package in "${packages[@]}"; do
    yay -S --noconfirm --needed "$package"
done
