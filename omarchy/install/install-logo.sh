#!/usr/bin/env bash

PLYMOUTH_THEME_PATH="/usr/share/plymouth/themes/omarchy"
LOGO_PATH="$HOME/.dotfiles/omarchy/logo.png"

sudo cp -f "${LOGO_PATH}" "${PLYMOUTH_THEME_PATH}"

sudo plymouth reload
sudo limine-update >/dev/null

echo "Custom logo installed."
