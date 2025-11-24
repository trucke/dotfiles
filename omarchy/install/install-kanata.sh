#!/usr/bin/env bash

yay -S --noconfirm --needed kanata-bin

if ! command -v kanata &>/dev/null; then
    echo "Kanshi installation failed."
    exit 1
fi

# Add user to required groups
sudo groupadd -rf uinput
sudo usermod -aG input "$USER"
sudo usermod -aG uinput "$USER"

# Configure udev rules
sudo tee /etc/udev/rules.d/99-input.rules >/dev/null <<'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

sudo udevadm control --reload-rules && sudo udevadm trigger

# Create systemd service
cat >~/.config/systemd/user/kanata.service <<'EOF'
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Environment=DISPLAY=:0
Type=simple
ExecStart=/usr/bin/sh -c 'exec $(which kanata) --cfg ${HOME}/.config/kanata/config.kbd'
Restart=no

[Install]
WantedBy=default.target
EOF

systemctl --user enable kanata.service

echo "Keyboard remapping successfully configured. Changes will take effect after reboot or next login."
