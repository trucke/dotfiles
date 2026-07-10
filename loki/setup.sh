#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

bash ./cleanup.sh
bash ./install/install-packages.sh
bash ./install/install-dotfiles.sh

# Generate this machine's per-machine SSH keys (github, net)
bash "${HOME}/.dotfiles/share/bin/ssh-keys-gen"

bash ./install/install-services.sh
bash ./install/configure.sh

omarchy-restart-terminal >/dev/null

cat <<'EOF'
Setup complete.

SSH: register the generated pubkeys (printed above), then from Proton Pass
install into ~/.ssh (chmod 600): shared keys (hlx-admin, roomvibes,
rv-edgeplayer, rv-edgeplayer-sync) + host config -> ~/.ssh/config.d/hosts.conf
EOF
