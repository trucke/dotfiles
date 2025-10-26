if [ "$(plymouth-set-default-theme)" != "heylogix" ]; then
    log "Configure plymouth theme..."
    sudo cp -r "${DOTFILES}/arch/config/plymouth" /usr/share/plymouth/themes/heylogix/
    sudo plymouth-set-default-theme heylogix
fi
################################################################################
KEYRING_DIR="$HOME/.local/share/keyrings"
KEYRING_FILE="$KEYRING_DIR/Default_keyring.keyring"
DEFAULT_FILE="$KEYRING_DIR/default"
mkdir -p $KEYRING_DIR
cat <<EOF | tee "$KEYRING_FILE" >/dev/null
[keyring]
display-name=Default keyring
ctime=$(date +%s)
mtime=0
lock-on-idle=false
lock-after=false
EOF
cat <<EOF | tee "$DEFAULT_FILE"
Default_keyring
EOF
chmod 700 "$KEYRING_DIR"
chmod 600 "$KEYRING_FILE"
chmod 644 "$DEFAULT_FILE"
################################################################################
log "Configure SDDM autologin..."
sudo mkdir -p /etc/sddm.conf.d
if [ ! -f /etc/sddm.conf.d/autologin.conf ]; then
    cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf >/dev/null
[Autologin]
User=$USER
Session=hyprland-uwsm

[Theme]
Current=breeze
EOF
fi
sudo systemctl -q enable sddm.service
################################################################################
log "Install and setup Limine Snapper integration..."
source "${DOTFILES_ARCH_INSTALL}/install-limine-snapper.sh"
