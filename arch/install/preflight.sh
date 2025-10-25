################################################################################
log "Setup pacman..."
sudo pacman -S --quiet --needed --noconfirm base-devel git &>/dev/null
sudo cp /etc/pacman.conf /etc/pacman.conf.bak
sudo sed -i '/^#Color/c\Color\nILoveCandy' /etc/pacman.conf
sudo sed -i '/^#VerbosePkgLists/c\VerbosePkgLists' /etc/pacman.conf
################################################################################
if ! command -v paru &>/dev/null; then
    log "Install AUR helper: paru"
    temp_dir=$(mktemp -d)
    cd "$temp_dir"

    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin
    makepkg -si --noconfirm

    cd ~ && rm -rf "$temp_dir" && paru --gendb
    paru -Syu --devel --noconfirm
fi
################################################################################
log "Temporarily disabling mkinitcpio hooks during installation..."
# Move the specific mkinitcpio pacman hooks out of the way if they exist
if [ -f /usr/share/libalpm/hooks/90-mkinitcpio-install.hook ]; then
    sudo mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled
fi
if [ -f /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook ]; then
    sudo mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled
fi
