sudo pacman -Syyy &>/dev/null
paru -Syy &>/dev/null
################################################################################
log "Install base packages..."
mapfile -t packages < <(/usr/bin/grep -v '^#' "${DOTFILES_ARCH_INSTALL}/base.packages" | /usr/bin/grep -v '^$')
paru -S --noconfirm --needed "${packages[@]}" >/dev/null
################################################################################
log "Install webapps..."
mkdir -p "${HOME}/.local/share/applications/icons"
omarchy-webapp-install "YouTube" https://youtube.com/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/youtube.png
omarchy-webapp-install "GitHub" https://github.com/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/github.png
omarchy-webapp-install "T3Chat" https://t3.chat/ https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/t3-chat.png
