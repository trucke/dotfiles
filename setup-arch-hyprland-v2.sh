#!/usr/bin/env bash

# Exit on any error, undefined variables, and pipe failures
set -euo pipefail

##############################################################################################################
# UTILITY FUNCTIONS
##############################################################################################################

# Install gum first for enhanced UI
install_gum() {
    if ! command -v gum >/dev/null 2>&1; then
        echo "Installing gum for enhanced UI..."
        sudo pacman -S --noconfirm gum || {
            # Fallback to AUR if not in official repos
            if command -v yay >/dev/null 2>&1; then
                yay -S --noconfirm gum
            else
                echo "Error: Could not install gum, which is required for this script"
                exit 1
            fi
        }
    fi
}

# Enhanced logging with gum
log() {
    gum style --foreground="#50fa7b" --bold "[$(date '+%H:%M:%S')]" "$*"
}

error() {
    gum style --foreground="#ff5555" --bold "[ERROR]" "$*" >&2
    exit 1
}

success() {
    gum style --foreground="#50fa7b" --bold "✓" "$*"
}

warning() {
    gum style --foreground="#ffb86c" --bold "⚠" "$*"
}

progress() {
    local current=$1
    local total=$2
    local task=$3
    
    gum style --foreground="#bd93f9" --bold "[$current/$total]" "$task"
}

show_header() {
    gum style \
        --foreground="#ff79c6" \
        --border="double" \
        --align="center" \
        --width=80 \
        --margin="1 2" \
        --padding="2 4" \
        "🚀 Arch Linux Hyprland Setup" \
        "" \
        "Automated installation and configuration" \
        "for a complete Hyprland desktop environment"
}

confirm_setup() {
    gum confirm "Ready to start the setup? This will install and configure your system." || exit 0
}

check_prerequisites() {
    progress 1 12 "Checking prerequisites..."
    
    gum spin --spinner dot --title "Validating environment..." -- sleep 1
    
    [[ -d ~/.dotfiles ]] || error "~/.dotfiles directory not found"
    command -v git >/dev/null || error "git is required"
    
    success "Prerequisites validated"
}

wait_for_service() {
    local service=$1
    local timeout=30
    
    gum spin --spinner dot --title "Waiting for service $service..." -- bash -c "
        while ! systemctl is-active --quiet '$service' && (($timeout > 0)); do
            sleep 1
            ((timeout--))
        done
    "
    
    [[ $timeout -gt 0 ]] || error "Service $service failed to start"
}

backup_file() {
    [[ -f "$1" ]] && cp "$1" "$1.bak.$(date +%s)"
}

detect_gpu() {
    if lspci | grep -qi amd; then
        echo "amd"
    elif lspci | grep -qi nvidia; then
        echo "nvidia"
    elif lspci | grep -qi intel; then
        echo "intel"
    else
        echo "unknown"
    fi
}

##############################################################################################################
# CONFIGURE PACMAN 
##############################################################################################################

configure_pacman() {
    progress 2 12 "Configuring pacman..."
    
    gum spin --spinner dot --title "Updating pacman configuration..." -- bash -c "
        sudo cp /etc/pacman.conf /etc/pacman.conf.bak
        sudo sed -i '/^#Color/c\Color\nILoveCandy' /etc/pacman.conf
        sudo sed -i '/^#VerbosePkgLists/c\VerbosePkgLists' /etc/pacman.conf
    "
    
    success "Pacman configured with colors and verbose package lists"
}

##############################################################################################################
# INSTALL YAY 
##############################################################################################################

install_yay() {
    progress 3 12 "Installing yay AUR helper..."
    
    # Install base development tools
    gum spin --spinner dot --title "Installing base development tools..." -- \
        sudo pacman -S --needed --noconfirm base-devel git

    if ! command -v yay &>/dev/null; then
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        gum spin --spinner dot --title "Building yay from AUR..." -- bash -c "
            git clone https://aur.archlinux.org/yay-bin.git
            cd yay-bin
            makepkg -si --noconfirm
        "
        
        cd ~
        rm -rf "$temp_dir"
        
        # Generate development package database
        yay -Y --gendb
        success "yay AUR helper installed"
    else
        success "yay already installed"
    fi

    # System upgrade with development packages
    log "Upgrading system..."
    gum spin --spinner dot --title "Upgrading system packages..." -- \
        yay -Syu --devel --noconfirm
    
    success "System upgraded"
}

##############################################################################################################
# PACKAGE INSTALLATION
##############################################################################################################

install_base_packages() {
    progress 4 12 "Installing base system packages..."
    
    local BASE_PACKAGES=(
        # System utilities
        smartmontools inetutils networkmanager openssh
        wget curl unzip wl-clipboard man-db nvtop btop
        
        # CLI tools
        vim bat eza fd fzf jq ripgrep stow bash-completion
        
        # Audio and system
        wireplumber sof-firmware libnewt
        
        # Desktop portal and utilities
        xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-utils
    )
    
    gum spin --spinner dot --title "Installing ${#BASE_PACKAGES[@]} base packages..." -- \
        yay -Sy --noconfirm --needed "${BASE_PACKAGES[@]}"
    
    success "Base packages installed"
}

install_gpu_drivers() {
    progress 5 12 "Installing GPU drivers..."
    
    local gpu_vendor=$(detect_gpu)
    log "Detected GPU: $gpu_vendor"
    
    case $gpu_vendor in
        amd)
            log "Installing AMD graphics drivers..."
            local AMD_PACKAGES=(
                libva-mesa-driver mesa vulkan-radeon
                xf86-video-amdgpu xf86-video-ati xorg-server xorg-xinit
            )
            gum spin --spinner dot --title "Installing AMD drivers..." -- \
                yay -Sy --noconfirm --needed "${AMD_PACKAGES[@]}"
            ;;
        nvidia)
            log "Installing NVIDIA graphics drivers..."
            local NVIDIA_PACKAGES=(
                nvidia nvidia-utils nvidia-settings
                libva-nvidia-driver
            )
            gum spin --spinner dot --title "Installing NVIDIA drivers..." -- \
                yay -Sy --noconfirm --needed "${NVIDIA_PACKAGES[@]}"
            ;;
        intel)
            log "Installing Intel graphics drivers..."
            local INTEL_PACKAGES=(
                libva-intel-driver mesa vulkan-intel
                xf86-video-intel xorg-server xorg-xinit
            )
            gum spin --spinner dot --title "Installing Intel drivers..." -- \
                yay -Sy --noconfirm --needed "${INTEL_PACKAGES[@]}"
            ;;
        *)
            warning "Unknown GPU vendor, installing generic drivers..."
            gum spin --spinner dot --title "Installing generic drivers..." -- \
                yay -Sy --noconfirm --needed xorg-server xorg-xinit mesa
            ;;
    esac
    
    success "GPU drivers installed"
}

install_hyprland_packages() {
    progress 6 12 "Installing Hyprland and desktop environment..."
    
    local HYPRLAND_PACKAGES=(
        # Core Hyprland
        hyprland hyprland-qtutils hyprpolkitagent hyprshot
        hypridle hyprlock hyprpaper
        
        # Wayland support
        qt5-wayland qt6-wayland
        
        # Desktop applications
        ghostty kitty nautilus sddm sushi swaync uwsm
        rofi-wayland waybar chromium
        
        # Network and wireless
        iwd wireless_tools networkmanager
    )
    
    gum spin --spinner dot --title "Installing ${#HYPRLAND_PACKAGES[@]} Hyprland packages..." -- \
        yay -Sy --noconfirm --needed "${HYPRLAND_PACKAGES[@]}"
    
    success "Hyprland packages installed"
}

install_additional_packages() {
    progress 7 12 "Installing additional system packages..."
    
    local ADDITIONAL_PACKAGES=(
        # Printing
        cups cups-filters cups-pdf poppler
        
        # System controls
        brightnessctl playerctl easyeffects
        power-profiles-daemon yubikey-manager
        
        # Bluetooth
        bluez bluez-utils bluetui
        
        # Shell
        zsh zsh-completions
        
        # Control panels
        pavucontrol blueman network-manager-applet system-config-printer
        
        # Desktop applications
        loupe evince nwg-bar zen-browser-bin obsidian
        proton-pass-bin proton-mail-bin proton-vpn-gtk-app
        libreoffice-fresh yubico-authenticator-bin
        mpv mpv-mpris celluloid
        
        # Display tools
        nwg-displays xiccd colord
        
        # Fonts
        ttf-font-awesome ttf-jetbrains-mono-nerd ttf-ubuntu-nerd
        ttf-atkinson-hyperlegible-next ttf-atkinson-hyperlegible-nerd
        
        # Theming
        gnome-themes-extra sddm-eucalyptus-drop
        
        # Keyboard remapping
        kanata-bin
    )
    
    gum spin --spinner dot --title "Installing ${#ADDITIONAL_PACKAGES[@]} additional packages..." -- \
        yay -Sy --noconfirm --needed "${ADDITIONAL_PACKAGES[@]}"
    
    success "Additional packages installed"
}

install_development_packages() {
    progress 8 12 "Installing development tools..."
    
    # Development dependencies
    gum spin --spinner dot --title "Installing development dependencies..." -- \
        yay -S --noconfirm --needed wxwidgets-gtk3 glu unixodbc
    
    # Install mise
    if ! command -v mise >/dev/null; then
        gum spin --spinner dot --title "Installing mise..." -- bash -c "
            curl -s https://mise.run | sh
            eval \"\$(~/.local/bin/mise activate bash)\"
            ~/.local/bin/mise install
        "
    fi
    
    local DEV_PACKAGES=(
        git jujutsu just air-bin tailwindcss-bin 
        bun-bin luarocks lazygit
    )
    
    gum spin --spinner dot --title "Installing development tools..." -- \
        yay -Sy --noconfirm --needed "${DEV_PACKAGES[@]}"
    
    success "Development tools installed"
}

##############################################################################################################
# SYSTEM CONFIGURATION
##############################################################################################################

configure_dotfiles() {
    progress 9 12 "Configuring dotfiles..."
    
    cd ~/.dotfiles
    
    # Backup existing hyprland config
    if [[ -d ~/.config/hypr ]]; then
        log "Backing up existing Hyprland configuration"
        mv ~/.config/hypr ~/.config/hypr.origin.$(date +%s)
    fi
    
    # Link configuration files
    gum spin --spinner dot --title "Linking configuration files..." -- \
        stow zshrc btop fastfetch ghostty git hyprland kitty nvim rofi starship tmux waybar mise ripgrep
    
    cd - >/dev/null
    success "Dotfiles configured"
}

enable_services() {
    progress 10 12 "Enabling system services..."
    
    gum spin --spinner dot --title "Enabling system services..." -- bash -c "
        sudo systemctl enable --now cups.service
        sudo systemctl enable --now bluetooth.service
        sudo systemctl enable power-profiles-daemon.service
    "
    
    wait_for_service cups
    wait_for_service bluetooth

    systemctl --user daemon-reload
    systemctl --user enable kanata.service
    
    success "System services enabled"
}

configure_shell() {
    log "Configuring shell..."
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        sudo chsh -s "$(which zsh)" "$USER"
        success "Shell changed to zsh (will take effect on next login)"
    else
        success "Shell already configured"
    fi
}

configure_mime_types() {
    log "Configuring MIME types and default applications..."
    
    update-desktop-database ~/.local/share/applications
    
    # Set default applications
    xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/gif image/bmp image/webp image/tiff
    xdg-mime default mpv.desktop video/mp4 video/mpeg video/ogg video/webm video/quicktime application/ogg
    xdg-mime default org.gnome.Nautilus.desktop inode/directory
    xdg-settings set default-web-browser zen.desktop
    
    success "MIME types configured"
}

configure_power_management() {
    log "Configuring power management..."
    
    # Just ensure the service is enabled (it will start after reboot)
    if systemctl is-enabled --quiet power-profiles-daemon 2>/dev/null; then
        success "power-profiles-daemon service is already enabled"
    else
        sudo systemctl enable power-profiles-daemon 2>/dev/null || true
        success "power-profiles-daemon service enabled"
    fi
    
    success "Power management will be available after desktop login"
}

configure_display() {
    log "Configuring display and color management..."
    
    # Skip display configuration if not in a graphical environment
    if [[ -z "${DISPLAY:-}" ]] && [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        warning "No display server detected - skipping color profile configuration"
        warning "Color profiles will be available after desktop login"
        
        # Still download and install the color profile for later use
        local color_profile='fw13-amd-color-profile.icm'
        sudo mkdir -p /usr/share/color/icc/colord
        
        if sudo curl -f -o "/usr/share/color/icc/colord/${color_profile}" \
            "https://www.notebookcheck.net/uploads/tx_nbc2/BOE_CQ_______NE135FBM_N41_03.icm"; then
            success "Color profile downloaded and installed"
        else
            warning "Could not download color profile (Framework 13 specific)"
        fi
        
        # Ensure colord service is enabled for desktop session
        sudo systemctl enable colord.service 2>/dev/null || true
        success "Color management service enabled for desktop session"
        return 0
    fi
    
    # Only proceed with full configuration if in a graphical environment
    log "Display server detected - configuring color management..."
    
    # Start color management daemon (only if display is available)
    if command -v xiccd >/dev/null && [[ -n "${DISPLAY:-}" ]]; then
        xiccd &
        sleep 2
        local xiccd_pid=$!
    fi
    
    # Download and install color profile (Framework 13 AMD specific)
    local color_profile='fw13-amd-color-profile.icm'
    sudo mkdir -p /usr/share/color/icc/colord
    
    if ! sudo curl -f -o "/usr/share/color/icc/colord/${color_profile}" \
        "https://www.notebookcheck.net/uploads/tx_nbc2/BOE_CQ_______NE135FBM_N41_03.icm"; then
        warning "Could not download color profile (Framework 13 specific)"
        return 0
    fi
    
    # Configure color management
    sudo systemctl restart colord.service
    wait_for_service colord
    
    # Wait a moment for colord to initialize
    sleep 2
    
    # Only try to configure device profile if we have a display
    if [[ -n "${DISPLAY:-}" ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        if color_profile_id=$(colormgr find-profile-by-filename "$color_profile" 2>/dev/null | grep Profile | awk '{print $3}'); then
            colormgr device-add-profile xrandr-eDP-1 "$color_profile_id" 2>/dev/null || warning "Could not add color profile to device (will be available after desktop login)"
        fi
    fi
    
    # Clean up background process if it was started
    if [[ -n "${xiccd_pid:-}" ]]; then
        kill $xiccd_pid 2>/dev/null || true
    fi
    
    success "Display configuration completed"
}

configure_keyboard() {
    log "Configuring keyboard remapping with Kanata..."
    
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
    cat > ~/.config/systemd/user/kanata.service <<EOF
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Environment=PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:$HOME/.cargo/bin
Environment=DISPLAY=:0
Type=simple
ExecStart=/usr/bin/sh -c 'exec \$(which kanata) --cfg \${HOME}/.config/kanata/config.kbd'
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
  l (multi f24 (tap-hold $tap-time $hold-time l ralt))
  ; (multi f24 (tap-hold $tap-time $hold-time ; rmet))
)

(deflayer base
  @escctrl @a @s @d @f @j @k @l @;
)
EOF
    
    success "Keyboard remapping configured"
}

configure_theming() {
    log "Configuring themes..."
    
    # Configure SDDM theme
    if [[ -f ~/.dotfiles/backgrounds/shaded-landscape.png ]]; then
        sudo cp -f ~/.dotfiles/backgrounds/shaded-landscape.png /usr/share/sddm/themes/eucalyptus-drop/Backgrounds/
    fi
    
    if [[ -f ~/.dotfiles/sddm/theme.conf ]]; then
        sudo cp -f ~/.dotfiles/sddm/theme.conf /usr/share/sddm/themes/eucalyptus-drop/
    fi
    
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/sddm.conf > /dev/null <<'EOF'
[Theme]
Current=eucalyptus-drop
EOF
    
    # Configure GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    
    success "Themes configured"
}

configure_web_apps() {
    progress 11 12 "Configuring web applications..."
    
    # Source the web2app function
    if [[ -f ~/.dotfiles/shell/functions ]]; then
        source ~/.dotfiles/shell/functions
        
        # Create web apps
        gum spin --spinner dot --title "Creating web applications..." -- bash -c '
            web2app "T3 Chat" "https://t3.chat/" "https://t3.chat/icon.png"
            web2app "Readwise Reader" "https://read.readwise.io/" "https://read.readwise.io/logo-dock-icon-with-padding/128x128@2x.png"
            web2app "LinkedIn" "https://linkedin.com/" "https://cdn.jsdelivr.net/gh/selfhst/icons/png/linkedin.png"
            web2app "Proton Drive" "https://drive.proton.me/u/0/" "https://cdn.jsdelivr.net/gh/selfhst/icons/png/proton-drive.png"
            web2app "solidtime" "https://app.solidtime.io/" "https://cdn.jsdelivr.net/gh/selfhst/icons/png/solidtime.png"
        '
        success "Web applications configured"
    else
        warning "web2app function not found, skipping web app configuration"
    fi
}

cleanup_bash_dotfiles() {
    progress 12 12 "Cleaning up bash dotfiles..."
    
    local bash_files=(.bash_history .bash_logout .bash_profile .bashrc)
    local cleaned_files=()
    
    for file in "${bash_files[@]}"; do
        if [[ -f ~/"$file" ]]; then
            backup_file ~/"$file"
            rm ~/"$file"
            cleaned_files+=("$file")
        fi
    done
    
    if [[ ${#cleaned_files[@]} -gt 0 ]]; then
        success "Cleaned up bash dotfiles: ${cleaned_files[*]}"
    else
        success "No bash dotfiles to clean up"
    fi
}

##############################################################################################################
# MAIN EXECUTION
##############################################################################################################

main() {
    # Install gum first for better UI (required)
    install_gum
    
    # Show header
    show_header
    
    # Confirm setup
    confirm_setup
    
    log "Starting Arch Linux Hyprland setup..."
    
    # Prerequisites
    check_prerequisites
    
    # System configuration
    configure_pacman
    install_yay
    
    # Package installation
    install_base_packages
    install_gpu_drivers
    install_hyprland_packages
    install_additional_packages
    
    # System configuration
    configure_dotfiles
    install_development_packages
    enable_services
    configure_shell
    configure_mime_types
    configure_power_management
    configure_display
    configure_keyboard
    configure_theming
    configure_web_apps
    
    # Final cleanup
    cleanup_bash_dotfiles
    
gum style \
    --foreground="#50fa7b" \
    --border="double" \
    --align="center" \
    --width=70 \
    --margin="1 2" \
    --padding="1 2" \
    "🎉 Setup completed successfully!" \
    "" \
    "Please reboot to ensure all changes take effect." \
    "You may need to log out and back in for shell changes." \
    "" \
    "📋 Post-Setup Tasks:" \
    "" \
    "After login, configure power profiles with:" \
    "• powerprofilesctl list" \
    "• powerprofilesctl set <profile>" \
    "" \
    "Color profiles will be automatically configured" \
    "by your desktop environment after login!" \
    "" \
    "Available profiles: power-saver, balanced, performance"
}

# Run main function
main "$@"
