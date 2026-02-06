#!/usr/bin/env bash

set -euo pipefail

DOTFILES="${HOME}/.dotfiles/omarchy/config/hypr"
HYPR_CONFIG="${HOME}/.config/hypr"

################################################################################

deploy_config() {
	local source_file="$1"
	local target_file="$2"
	local name="$3"

	if [ ! -f "${source_file}" ]; then
		echo "${name} source not found at ${source_file}"
		exit 1
	fi

	# Already a symlink pointing to the right place
	if [ -L "${target_file}" ] && [ "$(readlink -f "${target_file}")" = "$(readlink -f "${source_file}")" ]; then
		echo "${name} already deployed."
	else
		local backup_file="${target_file}.bak.$(date +%s)"
		echo "Deploy ${name}..."
		mv -f "${target_file}" "${backup_file}" 2>/dev/null || true
		ln -sfn "${source_file}" "${target_file}"
		echo "${name} deployed successfully."
	fi
}

################################################################################

# Hyprland override files (sourced by upstream hyprland.conf after defaults)
deploy_config "${DOTFILES}/monitors.conf" "${HYPR_CONFIG}/monitors.conf" "Monitors config"
deploy_config "${DOTFILES}/input.conf" "${HYPR_CONFIG}/input.conf" "Input config"
deploy_config "${DOTFILES}/bindings.conf" "${HYPR_CONFIG}/bindings.conf" "Bindings config"
deploy_config "${DOTFILES}/looknfeel.conf" "${HYPR_CONFIG}/looknfeel.conf" "Look-n-feel config"

# Standalone configs (not sourced by hyprland.conf, loaded by their own tools)
deploy_config "${DOTFILES}/hypridle.conf" "${HYPR_CONFIG}/hypridle.conf" "Hypridle config"
deploy_config "${DOTFILES}/hyprlock.conf" "${HYPR_CONFIG}/hyprlock.conf" "Hyprlock config"

hyprctl reload >/dev/null 2>&1 || true

echo "Hyprland overrides setup complete."
