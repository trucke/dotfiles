gnome_theme
################################################################################
################################################################################
log "Setup initial power profile and battery monitoring..."
powerprofilesctl set balanced || true
systemctl --user enable --now omarchy-battery-monitor.timer
################################################################################
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
################################################################################
# https://wiki.archlinux.org/title/Systemd-resolved
log "Setup DNS resolver..."
echo "Symlink resolved stub-resolv to /etc/resolv.conf"
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
################################################################################
log "Setup Gnome GTK theme..."
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface icon-theme "Yaru-purple"
sudo gtk-update-icon-cache /usr/share/icons/Yaru
