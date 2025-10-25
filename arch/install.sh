#!/usr/bin/env bash

# Exit on any error, undefined variables, and pipe failures
set -euo pipefail

DOTFILES_INSTALL="~/.dotfiles/arch/"

################################################################################
# UTILITY FUNCTIONS
################################################################################
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
    # Install all base packages
    mapfile -t packages < <(/usr/bin/grep -v '^#' "${DOTFILES_INSTALL}/base.packages" | /usr/bin/grep -v '^$')
    run "Install base packages..." sudo pacman -S --noconfirm --needed "${packages[@]}"
}

################################################################################
# INSTALL WEBAPPS
################################################################################
install_webapps() {
    run "Install webapp: Youtube..." \
        omarchy-webapp-install "YouTube" https://youtube.com/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/youtube.png
    run "Install webapp: Github..." \
        omarchy-webapp-install "GitHub" https://github.com/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/github.png
    run "Install webapp: T3Chat..." \
        omarchy-webapp-install "T3Chat" https://t3.chat/ https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/t3-chat.png
}

################################################################################
# DOCKER
################################################################################
configure_docker() {
    log "Configure and setup Docker..."
    # Configure Docker daemon:
    # - use host's DNS resolver
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json >/dev/null <<'EOF'
{
    "log-driver": "json-file",
    "log-opts": { "max-size": "10m", "max-file": "5" },
    "dns": ["172.17.0.1"],
    "bip": "172.17.0.1/16"
}
EOF

    # Expose systemd-resolved to our Docker network
    sudo mkdir -p /etc/systemd/resolved.conf.d
    echo -e '[Resolve]\nDNSStubListenerExtra=172.17.0.1' | sudo tee /etc/systemd/resolved.conf.d/20-docker-dns.conf >/dev/null
    sudo systemctl restart systemd-resolved

    # Start Docker automatically
    sudo systemctl enable docker

    # Give this user privileged Docker access
    sudo usermod -aG docker ${USER}

    # Prevent Docker from preventing boot for network-online.target
    sudo mkdir -p /etc/systemd/system/docker.service.d
    sudo tee /etc/systemd/system/docker.service.d/no-block-boot.conf <<'EOF'
[Unit]
DefaultDependencies=no
EOF

    sudo systemctl daemon-reload
}

################################################################################
# MIMETYPES
################################################################################
mimetypes() {
    update-desktop-database ~/.local/share/applications

    log "Configure mime types defaults..."
    # Open all images with imv
    xdg-mime default imv.desktop image/png
    xdg-mime default imv.desktop image/jpeg
    xdg-mime default imv.desktop image/gif
    xdg-mime default imv.desktop image/webp
    xdg-mime default imv.desktop image/bmp
    xdg-mime default imv.desktop image/tiff
    # Open PDFs with the Document Viewer
    xdg-mime default org.gnome.Evince.desktop application/pdf
    # Use Chromium as the default browser
    xdg-settings set default-web-browser helium-browser.desktop
    xdg-mime default helium-browser.desktop x-scheme-handler/http
    xdg-mime default helium-browser.desktop x-scheme-handler/https
    # Open video files with mpv
    xdg-mime default mpv.desktop video/mp4
    xdg-mime default mpv.desktop video/x-msvideo
    xdg-mime default mpv.desktop video/x-matroska
    xdg-mime default mpv.desktop video/x-flv
    xdg-mime default mpv.desktop video/x-ms-wmv
    xdg-mime default mpv.desktop video/mpeg
    xdg-mime default mpv.desktop video/ogg
    xdg-mime default mpv.desktop video/webm
    xdg-mime default mpv.desktop video/quicktime
    xdg-mime default mpv.desktop video/3gpp
    xdg-mime default mpv.desktop video/3gpp2
    xdg-mime default mpv.desktop video/x-ms-asf
    xdg-mime default mpv.desktop video/x-ogm+ogg
    xdg-mime default mpv.desktop video/x-theora+ogg
    xdg-mime default mpv.desktop application/ogg
    # Use Hey for mailto: links
    #xdg-mime default HEY.desktop x-scheme-handler/mailto
}

################################################################################
# WALKER - ELEPHANT
################################################################################
walker_elephant() {
    log "Configure walker + elephant..."
    # Create pacman hook to restart walker after updates
    sudo mkdir -p /etc/pacman.d/hooks
    sudo tee /etc/pacman.d/hooks/walker-restart.hook >/dev/null <<EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = walker
Target = walker-debug
Target = elephant*

[Action]
Description = Restarting Walker services after system update
When = PostTransaction
Exec = $DOTFILES/arch/bin/omarchy-restart-walker
EOF
}

################################################################################
# HARDWARE
################################################################################
network() {
    log "Enable 'iwd' network service..."
    # Ensure iwd service will be started
    sudo systemctl enable iwd.service
    # Prevent systemd-networkd-wait-online timeout on boot
    sudo systemctl disable systemd-networkd-wait-online.service
    sudo systemctl mask systemd-networkd-wait-online.service
}

printer() {
    log "Setup and configure printer system services..."

    sudo systemctl enable cups.service
    # Disable multicast dns in resolved. Avahi will provide this for better network printer discovery
    sudo mkdir -p /etc/systemd/resolved.conf.d
    echo -e "[Resolve]\nMulticastDNS=no" | sudo tee /etc/systemd/resolved.conf.d/10-disable-multicast.conf
    sudo systemctl enable avahi-daemon.service
    # Enable mDNS resolution for .local domains
    sudo sed -i 's/^hosts:.*/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve files myhostname dns/' /etc/nsswitch.conf
    # Enable automatically adding remote printers
    if ! grep -q '^CreateRemotePrinters Yes' /etc/cups/cups-browsed.conf; then
        echo 'CreateRemotePrinters Yes' | sudo tee -a /etc/cups/cups-browsed.conf
    fi

    sudo systemctl enable cups-browsed.service
}

usb_autosuspend() {
    log "Disable USB autosuspend to prevent peripheral disconnection issues..."
    if [[ ! -f /etc/modprobe.d/disable-usb-autosuspend.conf ]]; then
        echo "options usbcore autosuspend=-1" | sudo tee /etc/modprobe.d/disable-usb-autosuspend.conf
    fi
}

fix_f13_amd_audio_input() {
    log "Fix Framwork 13 AMD audo input issues..."
    AMD_AUDIO_CARD=$(pactl list cards 2>/dev/null | grep -B20 "Family 17h/19h" | grep "Name: " | awk '{print $2}' || true)

    if [[ -n $AMD_AUDIO_CARD ]]; then
        pactl set-card-profile "$AMD_AUDIO_CARD" "HiFi (Mic1, Mic2, Speaker)" 2>/dev/null || true
    fi
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

plymouth() {
    if [ "$(plymouth-set-default-theme)" != "heylogix" ]; then
        run "Configure plymouth theme..." bash -c "
            sudo cp -r "${DOTFILES}/arch/config/plymouth" /usr/share/plymouth/themes/heylogix/
            sudo plymouth-set-default-theme heylogix
        "
    fi
}

sddm() {
    log "Configure SDDM autologin..."
    sudo mkdir -p /etc/sddm.conf.d

    if [ ! -f /etc/sddm.conf.d/autologin.conf ]; then
        cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf
[Autologin]
User=$USER
Session=hyprland-uwsm

[Theme]
Current=breeze
EOF
    fi

    sudo systemctl enable sddm.service

    log "SDDM autologin successfully configured"
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
increase_lockout_limit() {
    run "Increase lockout limit to 10 and decrease timeout to 2 minutes..." bash -c "
        sudo sed -i 's|^\(auth\s\+required\s\+pam_faillock.so\)\s\+preauth.*$|\1 preauth silent deny=10 unlock_time=120|' "/etc/pam.d/system-auth"
        sudo sed -i 's|^\(auth\s\+\[default=die\]\s\+pam_faillock.so\)\s\+authfail.*$|\1 authfail deny=10 unlock_time=120|' "/etc/pam.d/system-auth"
    "
}

ssh_flakiness() {
    run "Solve common flakiness with SSH..." \
        echo "net.ipv4.tcp_mtu_probing=1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
}

detect_keyboard_layout() {
    log "Copy over the keyboard layout that's been set in Arch during install to Hyprland..."

    conf="/etc/vconsole.conf"
    hyprconf="$HOME/.config/hypr/input.conf"

    if grep -q '^XKBLAYOUT=' "$conf"; then
        layout=$(grep '^XKBLAYOUT=' "$conf" | cut -d= -f2 | tr -d '"')
        sed -i "/^[[:space:]]*kb_options *=/i\  kb_layout = $layout" "$hyprconf"
    fi

    if grep -q '^XKBVARIANT=' "$conf"; then
        variant=$(grep '^XKBVARIANT=' "$conf" | cut -d= -f2 | tr -d '"')
        sed -i "/^[[:space:]]*kb_options *=/i\  kb_variant = $variant" "$hyprconf"
    fi
}

fix_powerprofilesctl_shebang() {
    run "Ensure we use system python3 and not mise's python3..." \
        sudo sed -i '/env python3/ c\#!/bin/python3' /usr/bin/powerprofilesctl
}

fast_shutdown() {
    log "Speed up shutdown process..."

    sudo mkdir -p /etc/systemd/system.conf.d

    cat <<EOF | sudo tee /etc/systemd/system.conf.d/10-faster-shutdown.conf
[Manager]
DefaultTimeoutStopSec=5s
EOF
    sudo systemctl daemon-reload
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

battery_monitor() {
    run "Setup initial power profile and battery monitoring..." bash -c "
        powerprofilesctl set balanced || true
        systemctl --user enable --now omarchy-battery-monitor.timer
    "
}

firewall() {
    log "Setup firewall ..."
    # Allow nothing in, everything out
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    # Allow ports for LocalSend
    sudo ufw allow 53317/udp
    sudo ufw allow 53317/tcp
    # Allow SSH in
    sudo ufw allow 22/tcp
    # Allow Docker containers to use DNS on host
    sudo ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns'
    # Turn on the firewall
    sudo ufw --force enable
    # Enable UFW systemd service to start on boot
    sudo systemctl enable ufw
    # Turn on Docker protections
    sudo ufw-docker install
    sudo ufw reload
}

dns_resolver() {
    # https://wiki.archlinux.org/title/Systemd-resolved
    run "Setup DNS resolver..." bash -c "
        echo "Symlink resolved stub-resolv to /etc/resolv.conf"
        sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    "
}

gnome_theme() {
    run "Setup Gnome GTK theme..." bash -c "
        gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
        gsettings set org.gnome.desktop.interface icon-theme "Yaru-purple"
        sudo gtk-update-icon-cache /usr/share/icons/Yaru
    "
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

################################################################################
# GUARD
################################################################################
# Must have secure boot disabled
if bootctl status 2>/dev/null | grep -q 'Secure Boot: enabled'; then
    error "Secure Boot must be disabled!"
fi

# Must not have Gnome or KDE already install
if pacman -Qe gnome-shell &>/dev/null || pacman -Qe plasma-desktop &>/dev/null; then
    error "Fresh + Vanilla Arch installation is required!"
fi

command -v limine &>/dev/null || error "Limine bootloader is required!"

# Must have btrfs root filesystem
[ "$(findmnt -n -o FSTYPE /)" = "btrfs" ] || error "Btrfs root filesystem is required!"

log "Guards: OK"

################################################################################
# PREFLIGHT
################################################################################
setup_pacman
install_paru
disable_mkinitcpio

################################################################################
# PACKAGING
################################################################################
install_base_packages
install_webapps

################################################################################
# CONFIG
################################################################################
run "Link configuration files..." bash -c "
    stow --restow --dir="${DOTFILES}/share" --target="${HOME}" zshrc
    stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.config" config
    stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.local/bin" bin
    stow --restow --dir="${DOTFILES}/arch" --target="${HOME}/.config" config
    stow --restow --dir="${DOTFILES}/arch" --target="${HOME}/.local/bin" bin
"
increase_lockout_limit
ssh_flakiness
detect_keyboard_layout
fix_powerprofilesctl_shebang
configure_docker
mimetypes
walker_elephant
fast_shutdown

#--- HARDWARE ---#
network
run "Enable bluetooth service..." sudo systemctl enable bluetooth.service
printer
usb_autosuspend
# Disable shutting system down on power button to bind it to power menu afterwards
run "Disable power button for remap..." \
    sudo sed -i 's/.*HandlePowerKey=.*/HandlePowerKey=ignore/' /etc/systemd/logind.conf
fix_f13_amd_audio_input

################################################################################
# LOGIN
################################################################################
plymouth
sddm
run "Install and setup Limine Snapper integration..." source '${DOTFILES}/arch/install-limine-snapper.sh'

################################################################################
# POST-INSTALL
################################################################################
battery_monitor
firewall
dns_resolver
gnome_theme
