#!/usr/bin/env bash

log() {
    gum log --time TimeOnly --level info --time.foreground="#50fa7b" "$*"
}

configure_keyboard() {
    log "Configuring keyboard remapping with Kanata..."
    gum spin --spinner dot --title "Installing 'kanata'..." -- paru -S --noconfirm kanata-bin

    # Add user to required groups
    sudo groupadd -f uinput
    sudo usermod -aG input "$USER"
    sudo usermod -aG uinput "$USER"
    
    # Configure udev rules
    sudo tee /etc/udev/rules.d/99-input.rules > /dev/null <<'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF
    sudo udevadm control --reload-rules && sudo udevadm trigger
    
    # Create systemd service
    mkdir -p ~/.config/systemd/user
    cat > ~/.config/systemd/user/kanata.service <<'EOF'
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Environment=PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:$HOME/.cargo/bin
Environment=DISPLAY=:0
Type=simple
ExecStart=/usr/bin/sh -c 'exec $(which kanata) --cfg ${HOME}/.config/kanata/config.kbd'
Restart=no

[Install]
WantedBy=default.target
EOF
    
    # Create Kanata configuration
    mkdir -p ~/.config/kanata
    cat > ~/.config/kanata/config.kbd <<'EOF'
;; Kanata configuration for home row mods
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
  l (multi f24 (tap-hold $tap-time $hold-time l lalt))
  ; (multi f24 (tap-hold $tap-time $hold-time ; rmet))
)

(deflayer base
  @escctrl @a @s @d @f @j @k @l @;
)
EOF
}

if ! command -v paru >/dev/null 2>&1; then
    gum log --time TimeOnly --level error --time.foreground="#ff5555" "AUR helper 'paru' not installed"
    exit 1
fi

configure_keyboard

systemctl --user enable kanata.service &>/dev/null
log "Keyboard successfully configured. Changes will take effect after reboot or next login."
gum confirm "Would you like to reboot the system?" && sudo systemctl reboot
