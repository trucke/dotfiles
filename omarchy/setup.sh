#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

bash ./cleanup.sh
bash ./install/install-packages.sh
bash ./install/install-dotfiles.sh
bash ./install/install-applications.sh
bash ./install/install-hypr-overrides.sh
bash ./install/install-services.sh
bash ./install/configure.sh

echo "Setup complete."
