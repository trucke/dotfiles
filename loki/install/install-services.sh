#!/usr/bin/env bash

set -euo pipefail

# Kanata is installed by install-packages.sh; this wires its permissions and
# user service.

################################################################################
# Kanata (keyboard remapping)
################################################################################

bash "${HOME}/.dotfiles/loki/install/setup-kanata.sh"

################################################################################
# Syncthing (folder sync between the machines + NAS)
################################################################################
# Installed by install-packages.sh. Enabling the service is all that's declarative;
# device pairing + folder shares live in ~/.local/state/syncthing (stateful, done
# once via the GUI/API at http://127.0.0.1:8384).

systemctl --user enable --now syncthing.service
