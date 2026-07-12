#!/usr/bin/env bash

set -euo pipefail

# kanata + kanshi are installed by install-packages.sh; this only wires their
# permissions and user services.

################################################################################
# Kanata (keyboard remapping)
################################################################################

bash "${HOME}/.dotfiles/loki/install/setup-kanata.sh"

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
