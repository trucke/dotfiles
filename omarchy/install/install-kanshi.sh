#!/usr/bin/env bash

set -e

yay -S --noconfirm --needed kanshi

if ! command -v kanshi &>/dev/null; then
  echo "Kanshi installation failed."
  exit 1
fi

echo "exec-once = uwsm-app -- kanshi" >> $HOME/.config/hypr/autostart.conf

echo "Kanshi installed successfully!"
