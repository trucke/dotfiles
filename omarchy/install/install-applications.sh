#!/usr/bin/env bash

# Copy all bundled icons to the applications/icons directory

ICON_DIR="$HOME/.local/share/applications/icons"
cp ~/.dotfiles/omarchy/icons/*.png "$ICON_DIR/"

omarchy-webapp-install "T3Chat" https://t3.chat/ T3Chat.png
omarchy-webapp-install "Proton Mail" https://mail.proton.me/u/0/ Proton-Mail.png "" "x-scheme-handler/mailto"
omarchy-webapp-install "Proton Calendar" https://calendar.proton.me/u/0/ Proton-Calendar.png
omarchy-webapp-install "Proton Drive" https://drive.proton.me/u/0/ Proton-Drive.png
omarchy-webapp-install "Lumo" https://lumo.proton.me/u/0/ Lumo.png
omarchy-webapp-install "SimpleLogin" https://app.simplelogin.io/ SimpleLogin.png

echo "Web apps successfully installed."
