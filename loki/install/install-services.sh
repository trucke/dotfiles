#!/usr/bin/env bash

set -euo pipefail

# Kanata is installed by install-packages.sh; this wires its permissions and
# user service.

################################################################################
# Kanata (keyboard remapping)
################################################################################

bash "${HOME}/.dotfiles/loki/install/setup-kanata.sh"
