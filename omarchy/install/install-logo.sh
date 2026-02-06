#!/usr/bin/env bash

set -euo pipefail

DOTFILES="${HOME}/.dotfiles/omarchy"
PLYMOUTH_THEME_PATH="/usr/share/plymouth/themes/omarchy"

# Replace plymouth boot logo and rebuild initramfs
sudo cp -f "${DOTFILES}/logo.png" "${PLYMOUTH_THEME_PATH}/logo.png"
sudo plymouth-set-default-theme omarchy

if command -v limine-mkinitcpio &>/dev/null; then
	sudo limine-mkinitcpio
else
	sudo mkinitcpio -P
fi

echo "Custom logo installed."
