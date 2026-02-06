#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

bash ./install/install-packages.sh
bash ./install/install-dotfiles.sh
bash ./install/install-dev-tools.sh
bash ./install/install-applications.sh
bash ./install/install-hypr-overrides.sh
bash ./install/install-kanata.sh
bash ./install/install-kanshi.sh

bash ./install/set-shell.sh
bash ./install/set-default-apps.sh
bash ./install/set-background.sh
bash ./install/install-logo.sh
bash ./install/update-logind.sh

bash ./cleanup.sh

# Initialize theme (creates symlinks for ghostty, tmux, starship, waybar, etc.)
bash "${HOME}/.dotfiles/share/bin/theme-switch" rosepine

echo "Setup complete."
