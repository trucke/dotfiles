#!/usr/bin/env bash

set -euo pipefail

if [[ -f ~/.bashrc ]]; then
    mv ~/.bashrc ~/.bashrc.bak
fi

##############################################################################################################
# CONFIGURE PACMAN 
##############################################################################################################
sudo cp /etc/pacman.conf /etc/pacman.conf.bak
sudo sed -i "/^#Color/c\Color\nILoveCandy" /etc/pacman.conf
sudo sed -i "/^#VerbosePkgLists/c\VerbosePkgLists" /etc/pacman.conf

##############################################################################################################
# INSTALL YAY 
##############################################################################################################
sudo pacman -S --needed --noconfirm base-devel git

if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm
    cd ~ && rm -rf yay-bin
    # generate a development package database for *-git packages that were installed without yay
    yay -Y --gendb
fi

# system upgrade, but also check for development package updates
yay -Syu --devel

##############################################################################################################
# BASIC HYPRLAND INSTALLATION 
##############################################################################################################
yay -Sy --noconfirm --needed \
    smartmontools inetutils networkmanager openssh \
    wget curl unzip wl-clipboard man-db \
    vim bat eza fd fzf jq ripgrep stow bash-completion

# graphics drivers
yay -Sy --noconfirm --needed \
    libva-mesa-driver mesa radeontop vulkan-radeon \
    xf86-video-amdgpu xf86-video-ati xorg-server xorg-xinit

yay -Sy --noconfirm --needed \
    ghostty htop hyprland hyprland-qtutils hyprpolkitagent hyprshot iwd kitty nautilus networkmanager \
    qt5-wayland qt6-wayland sddm smartmontools sof-firmware sushi swaync uwsm libnewt \
    wget wireless_tools wireplumber wofi xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-utils \
    chromium

##############################################################################################################
# SYSTEM CONFIGURATION
##############################################################################################################
cd ~/.dotfiles
# backup current hyprland config
mv ~/.config/hypr ~/.config/hypr.origin
# link configuration files
stow zshrc btop fastfetch ghostty git hyprland kitty nvim rofi starship tmux waybar mise ripgrep #wofi
# cleanup bash dotfiles
rm .bash_history .bash_logout .bash_profile .bashrc

##############################################################################################################
# DEVELOPMENT 
##############################################################################################################
yay -S --noconfirm --needed wxwidgets-gtk3 glu unixodbc

curl https://mise.run | sh
eval "$(~/.local/bin/mise activate bash)"
~/.local/bin/mise install

yay -Sy --noconfirm --needed \
    git jujutsu just air-bin tailwindcss-bin bun-bin luarocks lazygit

##############################################################################################################
# ADDITIONNAL HYPRLAND PACKAGES
##############################################################################################################
# additional system tools
yay -Sy --noconfirm --needed \
    cups cups-filters cups-pdf poppler \
    brightnessctl playerctl easyeffects \
    bluez bluez-utils bluetui \
    power-profiles-daemon yubikey-manager \
    zsh zsh-completions
# controls & applets
yay -Sy --noconfirm --needed pavucontrol blueman network-manager-applet system-config-printer
# additionnal hyprland applications
yay -Sy --noconfirm --needed hypridle hyprlock hyprpaper rofi-wayland waybar
# additional desktop applications
yay -Sy --noconfirm --needed \
    loupe evince nwg-bar \
    zen-browser-bin obsidian \
    proton-pass-bin proton-mail-bin proton-vpn-gtk-app \
    libreoffice-fresh yubico-authenticator-bin \
    mpv mpv-mpris celluloid
# install system fonts
yay -Sy --noconfirm --needed \
    ttf-font-awesome ttf-jetbrains-mono-nerd ttf-ubuntu-nerd \
    ttf-atkinson-hyperlegible-next ttf-atkinson-hyperlegible-nerd

sudo systemctl enable --now cups.service
sudo systemctl enable --now bluetooth.service

sudo chsh -s $(which zsh)

##############################################################################################################
# CONFIGURE MIME TYPES & DEFAULTS
##############################################################################################################
update-desktop-database ~/.local/share/applications
# Open all images with loupe
xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/gif image/bmp image/webp image/tiff
# Open video files with mpv
xdg-mime default mpv.desktop video/mp4 video/mpeg video/ogg video/webm video/quicktime application/ogg
xdg-mime default org.gnome.Nautilus.desktop inode/directory

xdg-settings set default-web-browser zen.desktop

if ls /sys/class/power_supply/BAT* &>/dev/null; then
  powerprofilesctl set balanced # This computer runs on a battery
else
  powerprofilesctl set performance # This computer runs on power outlet
fi

##############################################################################################################
# DISPLAY CONFIGURATION
##############################################################################################################
color_profile='fw13-amd-color-profile.icm'
yay -Sy --noconfirm --needed nwg-displays xiccd colord
xiccd &

mkdir -p /usr/share/color/icc/colord
sudo curl -o /usr/share/color/icc/colord/${color_profile} https://www.notebookcheck.net/uploads/tx_nbc2/BOE_CQ_______NE135FBM_N41_03.icm

sudo systemctl restart colord.service
color_profile_id=$(colormgr find-profile-by-filename fw13-amd-color-profile.icm | grep Profile | awk '{print $3}')
colormgr device-add-profile xrandr-eDP-1 ${color_profile_id}
sudo systemctl restart colord.service

##############################################################################################################
# KEYBOARD CONFIGURATION - HOME ROW MODS
##############################################################################################################
yay -Sy --noconfirm kanata-bin

sudo groupadd uinput
sudo usermod -aG input $USER
sudo usermod -aG uinput $USER

sudo tee /etc/udev/rules.d/99-input.rules > /dev/null <<EOF
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF
sudo udevadm control --reload-rules && sudo udevadm trigger

cat > ~/.config/systemd/user/kanata.service <<EOF
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Environment=PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:$HOME/.cargo/bin
Environment=DISPLAY=:0
Type=simple
ExecStart=/usr/bin/sh -c 'exec $$(which kanata) --cfg $${HOME}/.config/kanata/config.kbd'
Restart=no

[Install]
WantedBy=default.target
EOF

mkdir -p ~/.config/kanata
cat > ~/.config/kanata/config.kbd <<EOF
;; defsrc is still necessary
(defcfg
  process-unmapped-keys yes
)

(defsrc
  caps a s d f j k l ;
)
(defvar
  tap-time 150
  hold-time 200
)

(defalias
  escctrl (tap-hold 100 100 esc lctl)
  a (multi f24 (tap-hold $tap-time $hold-time a lmet))
  s (multi f24 (tap-hold $tap-time $hold-time s lalt))
  d (multi f24 (tap-hold $tap-time $hold-time d lsft))
  f (multi f24 (tap-hold $tap-time $hold-time f lctl))
  j (multi f24 (tap-hold $tap-time $hold-time j rctl))
  k (multi f24 (tap-hold $tap-time $hold-time k rsft))
  l (multi f24 (tap-hold $tap-time $hold-time l ralt))
  ; (multi f24 (tap-hold $tap-time $hold-time ; rmet))
)

(deflayer base
  @escctrl @a @s @d @f @j @k @l @;
)
EOF

systemctl --user daemon-reload
systemctl --user enable kanata.service

##############################################################################################################
# THEMING
##############################################################################################################
yay -Sy --noconfirm gnome-themes-extra sddm-eucalyptus-drop
# theme and configure SDDM
sudo cp -f ~/.dotfiles/backgrounds/shaded-landscape.png /usr/share/sddm/themes/eucalyptus-drop/Backgrounds/
sudo cp -bf ~/.dotfiles/sddm/theme.conf /usr/share/sddm/themes/eucalyptus-drop/
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/sddm.conf > /dev/null <<EOF
[Theme]
Current=eucalyptus-drop
EOF
# set gnome/gtk apps theme defaults
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

##############################################################################################################
# CONFIGURE WEB APPS 
##############################################################################################################
source ~/.dotfiles/shell/functions

web2app "T3 Chat" https://t3.chat/ https://t3.chat/icon.png
web2app "Readwise Reader" https://read.readwise.io/ https://read.readwise.io/logo-dock-icon-with-padding/128x128@2x.png
web2app "LinkedIn" https://linkedin.com/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/linkedin.png
web2app "Proton Drive" https://drive.proton.me/u/0/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/proton-drive.png
web2app "solidtime" https://app.solidtime.io/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/solidtime.png

# web2app "YouTrack" https://heylogix.youtrack.cloud/ https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/jetbrains-youtrack.png
# web2app "Youtube" https://youtube.com/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/youtube.png
# web2app "Github" https://github.com/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/github.png
# web2app "Linkwarden" https://linkwarden.internal.kns.me https://cdn.jsdelivr.net/gh/selfhst/icons/png/linkwarden.png
# web2app "Claude" https://claude.ai/ https://cdn.jsdelivr.net/gh/selfhst/icons/png/claude.png
