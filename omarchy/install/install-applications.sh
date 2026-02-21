#!/usr/bin/env bash

set -euo pipefail

ICON_DIR="${HOME}/.local/share/applications/icons"
mkdir -p "${ICON_DIR}"
cp "${HOME}/.dotfiles/omarchy/icons/"*.png "${ICON_DIR}/"

omarchy-webapp-install "T3Chat" https://t3.chat/ T3Chat.png
omarchy-webapp-install "Proton Drive" https://drive.proton.me/u/0/ Proton-Drive.png
omarchy-webapp-install "SimpleLogin" https://app.simplelogin.io/ SimpleLogin.png

echo "Web apps installed."
