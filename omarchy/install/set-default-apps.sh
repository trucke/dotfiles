#!/usr/bin/env bash

omarchy-refresh-applications
update-desktop-database ~/.local/share/applications

echo "Set Helium Browser as the default browser"
xdg-settings set default-web-browser helium-browser.desktop
xdg-mime default helium-browser.desktop x-scheme-handler/http
xdg-mime default helium-browser.desktop x-scheme-handler/https

echo "Use Proton Mail for mailto: links"
xdg-mime default "Proton Mail.desktop" x-scheme-handler/mailto
