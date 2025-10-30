# Install all base packages
mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/base.packages" | grep -v '^$')
for package in "${packages[@]}"; do
    paru -S --noconfirm --needed "$package" >/dev/null 2>&1
    echo "[OK] '${package}' installed"
done
