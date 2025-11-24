#!/usr/bin/env bash

pushd "$HOME/.dotfiles/omarchy" >/dev/null

source ./install/install-packages.sh
source ./install/install-dotfiles.sh
source ./install/install-dev-tools.sh
source ./install/install-applications.sh
source ./install/install-hypr-overrides.sh
source ./install/install-kanata.sh
source ./install/install-kanshi.sh

source ./install/set-shell.sh
source ./install/set-default-apps.sh
source ./install/set-background.sh
source ./install/install-logo.sh
source ./install/update-logind.sh

source ./cleanup.sh

popd >/dev/null
