#!/usr/bin/env bash

log() {
    gum log --time TimeOnly --level info --time.foreground="#50fa7b" "$*"
}

warning() {
    gum log --time TimeOnly --level warn --time.foreground="#F0B100" "$*"
}

#############################################################################################################
#############################################################################################################
gum style \
        --foreground="#ff79c6" \
        --border="double" \
        --align="left" \
        --width=80 \
        --margin="1 2" \
        --padding="2 4" \
        "Configure display and color profile."

gum confirm "Ready to start the configuration?" || exit 0

# Skip display configuration if not in a graphical environment
if [[ -z "${DISPLAY:-}" ]] && [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    warning "No display server detected - skipping color profile configuration"
    exit 1
fi

# Download and install color profile (Framework 13 AMD specific)
color_profile='fw13-amd-color-profile.icm'
sudo mkdir -p /usr/share/color/icc/colord

log "Download Framework 13 AMD specific color profile..."
if ! sudo curl -# -f -o "/usr/share/color/icc/colord/${color_profile}" \
    "https://www.notebookcheck.net/uploads/tx_nbc2/BOE_CQ_______NE135FBM_N41_03.icm"; then
    warning "Could not download color profile (Framework 13 specific)"
    exit 1
fi

log "Start color profiling processes..."
# Ensure colord is running first
sudo systemctl restart colord.service
sleep 2
# start xiccd
setsid xiccd &>/dev/null &
sleep 2

profile_id=$(colormgr find-profile-by-filename "$color_profile" 2>/dev/null | grep Profile | awk '{print $3}')
log "Add color profile..."
colormgr device-add-profile "xrandr-eDP-1" "$profile_id" &>/dev/null
log "Set color profile as default..."
colormgr device-make-profile-default "xrandr-eDP-1" "$profile_id"

# Clean up background process if it was started
killall xiccd &>/dev/null || true

log "Display configuration completed"
