#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

export DOTFILES="${HOME}/.dotfiles"
export DOTFILES_ARCH_INSTALL="${DOTFILES}/arch/install"
export DOTFILES_INSTALL_LOG_FILE="/var/log/dotfiles-install.log"
export PATH="${DOTFILES}/arch/bin:${PATH}"

source "${DOTFILES_ARCH_INSTALL}/presentation.sh"

################################################################################

log() {
    gum log --time TimeOnly --time.foreground 7 --message.foreground 3 "$*"
}

################################################################################

clear_logo

################################################################################

abort() {
    echo -e "\e[31mInstall requires: $1\e[0m"
    echo
    gum confirm "Proceed anyway on your own accord and without assistance?" || exit 1
}

# Must have secure boot disabled
if bootctl status 2>/dev/null | grep -q 'Secure Boot: enabled'; then
    abort "Secure Boot disabled"
fi
# Must not have Gnome or KDE already install
if pacman -Qe gnome-shell &>/dev/null || pacman -Qe plasma-desktop &>/dev/null; then
    abort "Fresh + Vanilla Arch"
fi

command -v limine &>/dev/null || abort "Limine bootloader"

# Must have btrfs root filesystem
[ "$(findmnt -n -o FSTYPE /)" = "btrfs" ] || abort "Btrfs root filesystem"

log "Guards: OK"

################################################################################

log "Installing..."
echo

################################################################################

# Install
source "${DOTFILES_ARCH_INSTALL}/preflight.sh"
source "${DOTFILES_ARCH_INSTALL}/packaging.sh"
source "${DOTFILES_ARCH_INSTALL}/config.sh"
source "${DOTFILES_ARCH_INSTALL}/config-hardware.sh"
source "${DOTFILES_ARCH_INSTALL}/login.sh"
source "${DOTFILES_ARCH_INSTALL}/post-install.sh"

################################################################################

echo
clear_logo
echo

# Exit gracefully if user chooses not to reboot
if gum confirm --padding "0 0 0 $((PADDING_LEFT + 32))" --show-help=false --default --affirmative "Reboot Now" --negative "" ""; then
    # Clear screen to hide any shutdown messages
    clear
    if [[ -n "${OMARCHY_CHROOT_INSTALL:-}" ]]; then
        touch /var/tmp/omarchy-install-completed
        exit 0
    else
        sudo reboot 2>/dev/null
    fi
fi
