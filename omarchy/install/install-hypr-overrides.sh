#!/usr/bin/env bash

set -e

HYPRLAND_CONFIG="$HOME/.config/hypr/hyprland.conf"
HYPRLAND_BINDINGS="$HOME/.config/hypr/bindings.conf"
HYPRIDLE_CONFIG="$HOME/.config/hypr/hypridle.conf"
HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
HYPRPAPER_CONFIG="$HOME/.config/hypr/hyprpaper.conf"

DOTFILES="$HOME/.dotfiles/omarchy"

################################################################################

install_hyprland_overrides() {
    local hyperland_overrides_config="${DOTFILES}/config/hypr/hyprland-overrides.conf"
    local source_line="source = ${hyperland_overrides_config}"

    # Check if hyprland config exists
    if [ ! -f "$HYPRLAND_CONFIG" ]; then
        echo "Hyprland config not found at $HYPRLAND_CONFIG"
        echo "Please install hyprland first"
        exit 1
    fi

    # Check if overrides config exists
    if [ ! -f "${hyperland_overrides_config}" ]; then
        echo "Overrides config not found at ${hyperland_overrides_config}"
        exit 1
    fi

    # Check if source line already exists in hyprland.conf
    if grep -Fxq "${source_line}" "$HYPRLAND_CONFIG"; then
        echo "Source line already exists in $HYPRLAND_CONFIG"
    else
        echo "Adding source line to $HYPRLAND_CONFIG"
        echo "" >>"$HYPRLAND_CONFIG"
        echo "${source_line}" >>"$HYPRLAND_CONFIG"
        echo "Source line added successfully"
    fi

    echo "Hyprland overrides setup complete!"
}

install_hyprland_bindings_overrides() {
    local hyperland_overrides_bindings="${DOTFILES}/config/hypr/bindings.conf"
    local backup_file="${HYPRLAND_BINDINGS}.bak.$(date +%s)"

    if cmp -s "${hyperland_overrides_bindings}" "${HYPRLAND_BINDINGS}"; then
        echo "Hyperland user bindings overrides already deployed."
    else
        echo "Deploy Hyperland user bindings overrides..."
        mv -f "${HYPRLAND_BINDINGS}" "${backup_file}" 2>/dev/null
        ln "${hyperland_overrides_bindings}" "${HYPRLAND_BINDINGS}"
        echo "Hyprland user bindings overrides deployed successfully"
    fi

    echo "Hyprland user bindings overrides setup complete!"
}

install_hypridle_config() {
    local hypridle_config_override="${DOTFILES}/config/hypr/hypridle.conf"
    local backup_file="${HYPRIDLE_CONFIG}.bak.$(date +%s)"

    if cmp -s "${hypridle_config_override}" "${HYPRIDLE_CONFIG}"; then
        echo "Hypridle already deployed."
    else
        echo "Deploy Hypridle overrides..."
        mv -f "${HYPRIDLE_CONFIG}" "${backup_file}" 2>/dev/null
        ln "${hypridle_config_override}" "${HYPRIDLE_CONFIG}"
        echo "Hypridle config deployed successfully"
    fi

    echo "Hypridle overrides setup complete!"
}

install_hyprlock_config() {
    local hyprlock_config_override="${DOTFILES}/config/hypr/hyprlock.conf"
    local backup_file="${HYPRLOCK_CONFIG}.bak.$(date +%s)"

    if cmp -s "${hyprlock_config_override}" "${HYPRLOCK_CONFIG}"; then
        echo "Hypridle already deployed."
    else
        echo "Deploy Hypridle overrides..."
        mv -f "${HYPRLOCK_CONFIG}" "${backup_file}" 2>/dev/null
        ln "${hyprlock_config_override}" "${HYPRLOCK_CONFIG}"
        echo "Hypridle config deployed successfully"
    fi

    echo "Hypridle overrides setup complete!"
}

################################################################################

install_hyprland_overrides
install_hyprland_bindings_overrides
install_hypridle_config
install_hyprlock_config
