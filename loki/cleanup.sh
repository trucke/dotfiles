#!/usr/bin/env bash

set -euo pipefail

echo "Run system cleanup..."

# Remove preinstalled omarchy apps (webapps, TUIs, bindings)
omarchy-webapp-remove-all
omarchy-tui-remove-all

# Remove any symlink first to avoid overwriting dotfiles source through it
cp "${HOME}/.config/hypr/bindings.conf" "${HOME}/.config/hypr/bindings.conf.bak" 2>/dev/null || true
rm -f "${HOME}/.config/hypr/bindings.conf"
cp "${HOME}/.local/share/omarchy/default/hypr/plain-bindings.conf" "${HOME}/.config/hypr/bindings.conf"
hyprctl reload >/dev/null 2>&1 || true

# NOTE: package drops + npx-stub removal live in loki/sync.sh (idempotent, also
# re-run after every `omarchy update`). This script is fresh-provision only.

################################################################################

sudo rm -rf "${HOME}/Work" "${HOME}/go" "${HOME}/.cargo" "${HOME}/.npm"

rm -f "${HOME}/.XCompose"
rm -f "${HOME}/.bash_history" "${HOME}/.bash_logout" "${HOME}/.bash_profile"

rm -rf "${HOME}/.config/"{Typora,xournalpp,lazygit,fcitx5}
rm -f "${HOME}/.config/environment.d/fcitx.conf"

# Disable screensaver on idle (still available via force-launch in system menu)
mkdir -p "${HOME}/.local/state/omarchy/toggles"
touch "${HOME}/.local/state/omarchy/toggles/screensaver-off"

################################################################################

echo "Cleanup finished."
