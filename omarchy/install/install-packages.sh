#!/usr/bin/env bash

set -euo pipefail

mapfile -t packages <"${HOME}/.dotfiles/omarchy/install/install.packages"

yay -Syu --noconfirm
for package in "${packages[@]}"; do
	yay -S --noconfirm --needed "${package}"
done

if command -v mise &>/dev/null; then
	mise install -y
fi

echo "Packages and dev tools installed."
