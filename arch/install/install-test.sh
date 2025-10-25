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

clear_logo
log "Installing..."
echo

