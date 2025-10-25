log "Deploy dotfiles configurations..."
mkdir -p "${HOME}/.local/bin"
stow --restow --dir="${DOTFILES}/share" --target="${HOME}" zshrc
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.local/bin" bin
stow --restow --dir="${DOTFILES}/arch" --target="${HOME}/.config" config
stow --restow --dir="${DOTFILES}/arch" --target="${HOME}/.local/bin" bin
################################################################################
log "Increase lockout limit to 10 and decrease timeout to 2 minutes..."
sudo sed -i 's|^\(auth\s\+required\s\+pam_faillock.so\)\s\+preauth.*$|\1 preauth silent deny=10 unlock_time=120|' "/etc/pam.d/system-auth"
sudo sed -i 's|^\(auth\s\+\[default=die\]\s\+pam_faillock.so\)\s\+authfail.*$|\1 authfail deny=10 unlock_time=120|' "/etc/pam.d/system-auth"
################################################################################
log "Solve common flakiness with SSH..."
echo "net.ipv4.tcp_mtu_probing=1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
################################################################################
log "Copy over the keyboard layout that's been set in Arch during install to Hyprland..."
conf="/etc/vconsole.conf"
hyprconf="${HOME}/.config/hypr/input.conf"
if grep -q '^XKBLAYOUT=' "$conf"; then
    layout=$(grep '^XKBLAYOUT=' "$conf" | cut -d= -f2 | tr -d '"')
    sed -i "/^[[:space:]]*kb_options *=/i\  kb_layout = $layout" "$hyprconf"
fi
if grep -q '^XKBVARIANT=' "$conf"; then
    variant=$(grep '^XKBVARIANT=' "$conf" | cut -d= -f2 | tr -d '"')
    sed -i "/^[[:space:]]*kb_options *=/i\  kb_variant = $variant" "$hyprconf"
fi
################################################################################
log "Fix powerprofilesctl SHEBANG: Ensure we use system python3 and not mise's python3..."
sudo sed -i '/env python3/ c\#!/bin/python3' /usr/bin/powerprofilesctl
################################################################################
log "Configure and setup Docker..."
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
################################################################################
log "Configure mime types defaults..."
update-desktop-database ~/.local/share/applications
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
################################################################################
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
################################################################################
log "Speed up shutdown process..."
sudo mkdir -p /etc/systemd/system.conf.d
cat <<EOF | sudo tee /etc/systemd/system.conf.d/10-faster-shutdown.conf
[Manager]
DefaultTimeoutStopSec=5s
EOF
sudo systemctl daemon-reload
################################################################################
