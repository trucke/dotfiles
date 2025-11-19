#!/usr/bin/env bash

pushd "$HOME/.dotfiles/omarchy"

source ./install/install-packages.sh
source ./install/install-dotfiles.sh
source ./install/install-dev-tools.sh
source ./install/install-applications.sh
source ./install/install-hypr-overrides.sh
source ./install/update-logind.sh

source ./install/install-kanshi.sh
source ./install/install-kanata.sh

source ./install/set-shell.sh

source ./cleanup.sh

popd
