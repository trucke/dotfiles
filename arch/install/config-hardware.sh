log "Enable 'iwd' network service..."
# Ensure iwd service will be started
sudo systemctl -q enable iwd.service
# Prevent systemd-networkd-wait-online timeout on boot
sudo systemctl -q disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service
################################################################################
log "Enable bluetooth service..."
sudo systemctl enable bluetooth.service
################################################################################
log "Setup and configure printer system services..."
sudo systemctl -q enable cups.service
# Disable multicast dns in resolved. Avahi will provide this for better network printer discovery
sudo mkdir -p /etc/systemd/resolved.conf.d
echo -e "[Resolve]\nMulticastDNS=no" | sudo tee /etc/systemd/resolved.conf.d/10-disable-multicast.conf
sudo systemctl -q enable avahi-daemon.service
# Enable mDNS resolution for .local domains
sudo sed -i 's/^hosts:.*/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve files myhostname dns/' /etc/nsswitch.conf
# Enable automatically adding remote printers
if ! grep -q '^CreateRemotePrinters Yes' /etc/cups/cups-browsed.conf; then
    echo 'CreateRemotePrinters Yes' | sudo tee -a /etc/cups/cups-browsed.conf >/dev/null
fi
sudo systemctl -q enable cups-browsed.service
################################################################################
log "Disable USB autosuspend to prevent peripheral disconnection issues..."
if [[ ! -f /etc/modprobe.d/disable-usb-autosuspend.conf ]]; then
    echo "options usbcore autosuspend=-1" | sudo tee /etc/modprobe.d/disable-usb-autosuspend.conf >/dev/null
fi
################################################################################
log "Disable power button for remap..."
sudo sed -i 's/.*HandlePowerKey=.*/HandlePowerKey=ignore/' /etc/systemd/logind.conf
################################################################################
log "Fix Framwork 13 AMD audo input issues..."
AMD_AUDIO_CARD=$(pactl list cards 2>/dev/null | grep -B20 "Family 17h/19h" | grep "Name: " | awk '{print $2}' || true)
if [[ -n $AMD_AUDIO_CARD ]]; then
    pactl set-card-profile "$AMD_AUDIO_CARD" "HiFi (Mic1, Mic2, Speaker)" 2>/dev/null || true
fi
