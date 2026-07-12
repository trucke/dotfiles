#!/usr/bin/env bash

set -euo pipefail

command -v kanata >/dev/null 2>&1 || { echo "kanata not found — install kanata-bin first"; exit 1; }

sudo groupadd -rf uinput
sudo usermod -aG input "${USER}"
sudo usermod -aG uinput "${USER}"

sudo tee /etc/modules-load.d/uinput.conf >/dev/null <<'EOF'
uinput
EOF
sudo tee /etc/udev/rules.d/99-input.rules >/dev/null <<'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

sudo modprobe uinput
sudo udevadm control --reload-rules
sudo udevadm trigger

mkdir -p "${HOME}/.config/systemd/user"
cat >"${HOME}/.config/systemd/user/kanata.service" <<'EOF'
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Environment=DISPLAY=:0
Type=simple
ExecStart=/usr/bin/sh -c 'exec /usr/bin/kanata --cfg ${HOME}/.config/kanata/config.kbd'
Restart=on-failure

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable kanata.service
systemctl --user reset-failed kanata.service
systemctl --user restart kanata.service
systemctl --user --no-pager status kanata.service

echo "Kanata configured. Log out and back in if input/uinput groups were newly added."
