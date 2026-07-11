#!/usr/bin/env bash

set -euo pipefail

################################################################################
# Theme
################################################################################

omarchy theme set "Catppuccin"

################################################################################
# Shell
################################################################################

ZSH_PATH="$(command -v zsh)"

if [ "${SHELL}" != "${ZSH_PATH}" ]; then
	if ! grep -q "^${ZSH_PATH}$" /etc/shells; then
		echo "${ZSH_PATH}" | sudo tee -a /etc/shells >/dev/null
	fi
	chsh -s "${ZSH_PATH}"
	echo "Default shell changed to zsh."
fi

################################################################################
# Default applications
################################################################################

omarchy-refresh-applications
update-desktop-database "${HOME}/.local/share/applications"

# Default browser -> Brave Origin. brave-origin-bin ships brave-origin.desktop;
# it's Chromium-family, so it also serves Omarchy web apps via --app (why we drop
# the chromium package in sync.sh). NB: `omarchy-default-browser brave-origin`
# targets brave-origin-BETA.desktop, which this package doesn't provide, so set
# the http/https/html handlers directly to the real desktop id.
xdg-settings set default-web-browser brave-origin.desktop
xdg-mime default brave-origin.desktop x-scheme-handler/http
xdg-mime default brave-origin.desktop x-scheme-handler/https
xdg-mime default brave-origin.desktop text/html

xdg-mime default proton-mail.desktop x-scheme-handler/mailto

################################################################################
# Logind (lid switch behavior)
################################################################################

# Back up the pristine original once. Guarded so re-runs neither pile up
# timestamped copies nor overwrite the backup with already-modified state.
[ -f /etc/systemd/logind.conf.orig ] || sudo cp /etc/systemd/logind.conf /etc/systemd/logind.conf.orig
sudo sed -i 's/^#\?HandleLidSwitch=/HandleLidSwitch=/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=suspend/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?HandleLidSwitchDocked=/HandleLidSwitchDocked=/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?LidSwitchIgnoreInhibited=/LidSwitchIgnoreInhibited=/' /etc/systemd/logind.conf

################################################################################

echo "System configured."
