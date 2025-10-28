# Install all base packages
mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/base.packages" | grep -v '^$')
paru -Syu --noconfirm --needed "${packages[@]}"
