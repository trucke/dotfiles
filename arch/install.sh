#!/usr/bin/env bash

# Exit on any error, undefined variables, and pipe failures
set -euo pipefail

################################################################################
# UTILITY FUNCTIONS
################################################################################
install_gum() {
    if command -v gum &>/dev/null; then
        return
    fi

    echo "Installing gum for enhanced UI..."
    sudo pacman -Sy --noconfirm gum || {
        echo "Error: Could not install gum, which is required for this script"
        exit 1
    }
}

log() {
    gum log --time TimeOnly --level info --time.foreground="#50fa7b" "$*"
}

error() {
    gum log --time TimeOnly --level error --time.foreground="#ff5555" "$*"
    exit 1
}

run() {
    local title="$1"
    shift
    log "$title"
    gum spin --spinner dot --title "$title" -- "$@"
}

################################################################################
# PACMAN SETUP
################################################################################
setup_pacman() {
    run "Installing base development tools..." \
        sudo pacman -S --needed --noconfirm base-devel git

    run "Updating pacman configuration..." bash -c "
        sudo cp /etc/pacman.conf /etc/pacman.conf.bak
        sudo sed -i '/^#Color/c\Color\nILoveCandy' /etc/pacman.conf
        sudo sed -i '/^#VerbosePkgLists/c\VerbosePkgLists' /etc/pacman.conf
    "
}

################################################################################
# INSTALL PARU
################################################################################
install_paru() {
    command -v paru &>/dev/null && return

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    run "Building paru from AUR..." bash -c "
        git clone https://aur.archlinux.org/paru-bin.git
        cd paru-bin
        makepkg -si --noconfirm
    "

    cd ~ && rm -rf "$temp_dir" && paru --gendb
    run "Upgrading system packages..." paru -Syu --devel --noconfirm
}

################################################################################
# TEMPORARILY DISABLE mkinitcpio
################################################################################
disable_mkinitcpio() {
    # Temporarily disable mkinitcpio hooks to prevent multiple regenerations during package installation
    #
    log "Temporarily disabling mkinitcpio hooks during installation..."
    # Move the specific mkinitcpio pacman hooks out of the way if they exist
    if [ -f /usr/share/libalpm/hooks/90-mkinitcpio-install.hook ]; then
        sudo mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled
    fi
    if [ -f /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook ]; then
        sudo mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled
    fi

    log "mkinitcpio hooks disabled"
}

################################################################################
# INSTALL PACKAGES
################################################################################
install_base_packages() {
    mapfile -t packages < <(grep -v '^#' "~/.dotfiles/arch/base.packages" | grep -v '^$')
    run "Install base packages..." sudo pacman -S --noconfirm --needed "${packages[@]}"
}

################################################################################
# INSTALL WEBAPPS
################################################################################
install_webapps() {
    omarchy-webapp-install "YouTube" https://youtube.com/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/youtube.png
    omarchy-webapp-install "GitHub" https://github.com/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/github.png
    omarchy-webapp-install "T3Chat" https://t3.chat/ https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/t3-chat.png
}
