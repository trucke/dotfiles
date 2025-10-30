#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

export DOTFILES="${HOME}/.dotfiles"

export OMARCHY_ONLINE_INSTALL=true
# Define Omarchy locations
export OMARCHY_PATH="${DOTFILES}/omarchy"
export OMARCHY_INSTALL="${OMARCHY_PATH}/install"
export OMARCHY_INSTALL_LOG_FILE="/var/log/omarchy-install.log"
export PATH="$OMARCHY_PATH/bin:$PATH"

# Helpers
source "$OMARCHY_INSTALL/helpers/logging.sh"
source "$OMARCHY_INSTALL/helpers/errors.sh"
source "$OMARCHY_INSTALL/helpers/presentation.sh"
source "$OMARCHY_INSTALL/helpers/chroot.sh"

clear_logo
gum style --bold --padding "1 0 1 $PADDING_LEFT" --foreground 5 "INSTALLING ..."
start_install_log

# Install
source "$OMARCHY_INSTALL/preflight/all.sh"
source "$OMARCHY_INSTALL/packaging/all.sh"
source "$OMARCHY_INSTALL/config/all.sh"
source "$OMARCHY_INSTALL/login/all.sh"
source "$OMARCHY_INSTALL/post-install/all.sh"
