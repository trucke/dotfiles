if [ "$(plymouth-set-default-theme)" != "heylogix" ]; then
    log "Configure plymouth theme..."
    sudo cp -r "${DOTFILES}/arch/config/plymouth" /usr/share/plymouth/themes/heylogix/
    sudo plymouth-set-default-theme heylogix
fi
################################################################################
log "Configure SDDM autologin..."
sudo mkdir -p /etc/sddm.conf.d
if [ ! -f /etc/sddm.conf.d/autologin.conf ]; then
    cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf
[Autologin]
User=$USER
Session=hyprland-uwsm

[Theme]
Current=breeze
EOF
fi
sudo systemctl enable sddm.service
################################################################################
log "Install and setup Limine Snapper integration..." 
source "${DOTFILES_ARCH_INSTALL}/install-limine-snapper.sh"
