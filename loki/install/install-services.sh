#!/usr/bin/env bash

set -euo pipefail

# kanata + kanshi are installed by install-packages.sh; this only wires their
# permissions and user services.

################################################################################
# Kanata (keyboard remapping)
################################################################################

sudo groupadd -rf uinput
sudo usermod -aG input "${USER}"
sudo usermod -aG uinput "${USER}"

sudo tee /etc/udev/rules.d/99-input.rules >/dev/null <<'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

sudo udevadm control --reload-rules && sudo udevadm trigger

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
systemctl --user restart kanata.service || true

echo "Kanata service configured."

################################################################################
# Kanshi (display auto-config)
################################################################################

cat >"${HOME}/.config/systemd/user/kanshi.service" <<'EOF'
[Unit]
Description=Kanshi output manager
Documentation=man:kanshi(1)
PartOf=graphical-session.target

[Service]
ExecStart=/usr/bin/kanshi
Restart=always
RestartSec=2

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable kanshi.service
systemctl --user restart kanshi.service || true

echo "Kanshi service configured."
