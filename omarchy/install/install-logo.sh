#!/usr/bin/env bash

set -euo pipefail

DOTFILES="${HOME}/.dotfiles/omarchy"
PLYMOUTH_THEME_PATH="/usr/share/plymouth/themes/omarchy"

# Plymouth boot logo
sudo cp -f "${DOTFILES}/logo.png" "${PLYMOUTH_THEME_PATH}/logo.png"
sudo plymouth reload
sudo limine-update >/dev/null

echo "Custom logo installed."
