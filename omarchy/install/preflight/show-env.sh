if ! command -v gum &>/dev/null; then
    sudo pacman -S -q --needed --noconfirm gum >/dev/null
fi

echo
# Show installation environment variables
log "Installation Environment:" 5 8

env | grep -E "^(OMARCHY_CHROOT_INSTALL|OMARCHY_ONLINE_INSTALL|OMARCHY_USER_NAME|OMARCHY_USER_EMAIL|USER|HOME|OMARCHY_REPO|OMARCHY_REF|OMARCHY_PATH)=" | sort | while IFS= read -r var; do
    log "${var}" 7 8
done

echo
