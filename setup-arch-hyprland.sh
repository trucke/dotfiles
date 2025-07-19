#!/usr/bin/env bash

# Exit on any error, undefined variables, and pipe failures
set -euo pipefail

###############################################################################
# UTILITY FUNCTIONS
###############################################################################
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

###############################################################################
###############################################################################

configure_pacman() {
    run "Updating pacman configuration..." bash -c "
        sudo cp /etc/pacman.conf /etc/pacman.conf.bak
        sudo sed -i '/^#Color/c\Color\nILoveCandy' /etc/pacman.conf
        sudo sed -i '/^#VerbosePkgLists/c\VerbosePkgLists' /etc/pacman.conf
    "
}

install_paru() {
    if command -v paru &>/dev/null; then
        return
    fi

    run "Installing base development tools..." sudo pacman -S --needed --noconfirm base-devel git

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

install_base_packages() {
    log "Installing base system packages..."
    local BASE_PACKAGES=(
        # System utilities
        inetutils networkmanager iwd wpa_supplicant openssh wget curl unzip man-db nvtop
        wireplumber sof-firmware fw-fanctrl
        # CLI tools
        vim neovim bat eza fd fzf jq ripgrep stow rsync zsh zsh-completions starship 
        rclone docker docker-compose jujutsu tmux
        # Bluetooth tools
        bluez bluez-utils bluetui
        # printer support
        cups cups-filters cups-pdf avahi
    )
    
    run "Installing ${#BASE_PACKAGES[@]} base packages..." \
        paru -Sy --noconfirm --needed "${BASE_PACKAGES[@]}"

    sudo usermod -aG docker "${USER}"
    sudo chsh -s "$(which zsh)" "$USER"
}

install_hyprland_packages() {
    log "Installing Hyprland and desktop environment..."
    local HYPRLAND_PACKAGES=(
        # Hyprland
        hypridle hyprland hyprlock hyprpaper hyprpolkitagent hyprshot swaync rofi-wayland waybar
        wl-clipboard xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-utils qt6-wayland
        gnome-themes-extra
        # File manager & viewers
        thunar thunar-volman gvfs tumbler loupe evince
        ffmpegthumbnailer poppler-glib
        # Desktop applications
        ghostty zen-browser-bin chromium obsidian yubikey-manager proton-pass-bin
        # System controls
        brightnessctl playerctl easyeffects power-profiles-daemon pavucontrol
        # Fonts and symbols
        ttf-font-awesome ttf-jetbrains-mono-nerd ttf-atkinson-hyperlegible-next ttf-nerd-fonts-symbols
        noto-fonts-emoj
        # AMD graphics driver
        libva-mesa-driver mesa vulkan-radeon xf86-video-amdgpu xf86-video-ati xorg-server xorg-xinit
        # display & color profiling
        xiccd colord
    )
    
    run "Installing ${#HYPRLAND_PACKAGES[@]} Hyprland packages..." \
        paru -Sy --noconfirm --needed "${HYPRLAND_PACKAGES[@]}"


    run "Configure GTK theme" bash -c "
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface font-name 'Atkinson Hyperlegible Next 11'
    "

    run "Configuring MIME types and default applications..." bash -c "
        update-desktop-database ~/.local/share/applications &>/dev/null || true
        xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/gif image/bmp image/webp image/tiff
        xdg-mime default mpv.desktop video/mp4 video/mpeg video/ogg video/webm video/quicktime application/ogg
        xdg-mime default thunar.desktop inode/directory application/x-gnome-saved-search
        xdg-settings set default-web-browser zen.desktop
    " 
}

install_development_packages() {
    if command -v mise &>/dev/null; then
        return
    fi

    run "Installing mise..." bash -c "
        paru -S --noconfirm --needed wxwidgets-gtk3 glu unixodbc
        curl -s https://mise.run | sh
        eval \"\$(~/.local/bin/mise activate bash)\"
        ~/.local/bin/mise install
    "

    run "Install dev tools..." bash -c "
        export GOBIN=\"~/.local/share/bin\"
        export GOPATH=\"~/.local/share/go\"
        go install github.com/air-verse/air@latest
        go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
        go install github.com/pressly/goose/v3/cmd/goose@latest
        paru -S --noconfirm just tailwindcss-bin
    "
}

configure_dotfiles() {
    mv ~/.config/hypr ~/.config/hypr.origin.$(date +%s) &>/dev/null || true
    pushd "${HOME}/.dotfiles" &>/dev/null
    run "Linking dotfiles..." \
        stow ghostty git hyprland mise nvim ripgrep rofi scripts starship tmux waybar zshrc
    popd &>/dev/null
}

enable_services() {
    run "Enabling system services..." bash -c "
        sudo systemctl daemon-reload
        sudo systemctl enable cups.service
        sudo systemctl enable bluetooth.service
        sudo systemctl enable power-profiles-daemon.service
        sudo systemctl enable docker.service
        sudo systemctl enable avahi-daemon.service
        sudo systemctl enable fw-fanctrl.service
        systemctl --user daemon-reload
        sleep 3
    "
}

configure_web_apps() {
    run "Creating web applications..." bash -c '
        source ~/.dotfiles/shell/functions
        web2app "T3 Chat" "https://t3.chat/" "https://t3.chat/icon.png"
        web2app "Readwise Reader" "https://read.readwise.io/" "https://read.readwise.io/logo-dock-icon-with-padding/128x128@2x.png"
        web2app "LinkedIn" "https://linkedin.com/" "https://cdn.jsdelivr.net/gh/selfhst/icons/png/linkedin.png"
        web2app "Proton Drive" "https://drive.proton.me/u/0/" "https://cdn.jsdelivr.net/gh/selfhst/icons/png/proton-drive.png"
        web2app "Proton Mail" "https://mail.proton.me/u/0/inbox" "https://cdn.jsdelivr.net/gh/selfhst/icons/png/proton-mail.png"
        web2app "solidtime" "https://app.solidtime.io/" "https://cdn.jsdelivr.net/gh/selfhst/icons/png/solidtime.png"
    '
}

install_tmux_plugin_manager() {
    run "Clone Tmux Plugin Manager..." \
        git clone https://github.com/tmux-plugins/tpm "${HOME}/.local/share/tmux/plugins/tpm"
    run "Install Tmux plugins..." bash "${HOME}/.local/share/tmux/plugins/tpm/bin/install_plugins"
}

configure_auto_login() {
    # Login directly as user, rely on disk encryption + hyprlock for security
    run "Configure auto-login..." bash -c "
    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
    sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf >/dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF
    "
}

###############################################################################
# MAIN EXECUTION
###############################################################################
    # Install gum first for better UI (required)
    install_gum
    
    gum style \
        --foreground="#ff79c6" \
        --border="double" \
        --align="center" \
        --width=80 \
        --margin="1 2" \
        --padding="2 4" \
        "Arch Linux Hyprland Setup" \
        "" \
        "Automated installation and configuration" \
        "for a complete Hyprland desktop environment"

    gum confirm "Ready to start the setup? This will install and configure your system." || exit 0

    # run setup
    configure_pacman
    install_paru

    install_base_packages
    install_hyprland_packages
    configure_dotfiles
    configure_auto_login
    install_development_packages
    configure_web_apps
    enable_services

    install_tmux_plugin_manager

    # Final cleanup
    run "Cleaning up bash dotfiles..." rm -rf ~/.bash{_history,_logout,_profile,rc}
    run "Creating personal directories..." mkdir -p ~/development/ ~/Documents/

    gum style \
        --foreground="#50fa7b" \
        --border="double" \
        --align="center" \
        --width=70 \
        --margin="1 2" \
        --padding="1 2" \
        "🎉 Setup completed successfully!" \
        "" \
        "Please reboot to ensure all changes take effect." \
        "You may need to log out and back in for shell changes." \
        ""
