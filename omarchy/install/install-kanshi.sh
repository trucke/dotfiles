#!/usr/bin/env bash

set -e

yay -S --noconfirm --needed kanshi

if ! command -v kanshi &>/dev/null; then
    echo "Kanshi installation failed."
    exit 1
fi

KANSHI_SERVICE="${HOME}/.config/systemd/user/kanshi.service"

if [ ! -f "${KANSHI_SERVICE}"; then
    echo "Kanshi systemd service not found."
    echo "Install systemd service..."
    # Create systemd service
    cat >"${KANSHI_SERVICE}" <<'EOF'
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

    echo "Systemd service installed successfully"
fi

echo "Kanshi installed successfully!"
