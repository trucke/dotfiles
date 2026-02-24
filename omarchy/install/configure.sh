#!/usr/bin/env bash

set -euo pipefail

################################################################################
# Theme
################################################################################

bash "${HOME}/.dotfiles/share/bin/theme-switch" rosepine

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
# Background
################################################################################

omarchy-theme-bg-set "${HOME}/.dotfiles/share/backgrounds/rose-pine.png"

################################################################################
# Boot logo
################################################################################

PLYMOUTH_THEME_PATH="/usr/share/plymouth/themes/omarchy"

sudo cp -f "${HOME}/.dotfiles/omarchy/logo.png" "${PLYMOUTH_THEME_PATH}/logo.png"
sudo plymouth-set-default-theme omarchy

if command -v limine-mkinitcpio &>/dev/null; then
	sudo limine-mkinitcpio
else
	sudo mkinitcpio -P
fi

################################################################################
# Logind (lid switch behavior)
################################################################################

sudo cp /etc/systemd/logind.conf{,.backup-"$(date +%s)"}
sudo sed -i 's/^#\?HandleLidSwitch=/HandleLidSwitch=/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?HandleLidSwitchDocked=/HandleLidSwitchDocked=/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?LidSwitchIgnoreInhibited=/LidSwitchIgnoreInhibited=/' /etc/systemd/logind.conf

################################################################################

echo "System configured."
