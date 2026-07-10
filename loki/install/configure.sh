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

xdg-mime default proton-mail.desktop x-scheme-handler/mailto

################################################################################
# Logind (lid switch behavior)
################################################################################

sudo cp /etc/systemd/logind.conf{,.backup-"$(date +%s)"}
sudo sed -i 's/^#\?HandleLidSwitch=/HandleLidSwitch=/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=suspend/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?HandleLidSwitchDocked=/HandleLidSwitchDocked=/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?LidSwitchIgnoreInhibited=/LidSwitchIgnoreInhibited=/' /etc/systemd/logind.conf

################################################################################

echo "System configured."
