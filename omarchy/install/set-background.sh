#!/usr/bin/env bash

NEW_BACKGROUND="${HOME}/.dotfiles/share/backgrounds/rose-pine.png"
CURRENT_BACKGROUND_LINK="$HOME/.config/omarchy/current/background"

# Set new background symlink
ln -nsf "$NEW_BACKGROUND" "$CURRENT_BACKGROUND_LINK"

# Relaunch swaybg
pkill -x swaybg
sh -c 'setsid uwsm-app -- swaybg -i "$CURRENT_BACKGROUND_LINK" -m fill >/dev/null 2>&1 &'

echo ""
echo "Background changed successfully."
