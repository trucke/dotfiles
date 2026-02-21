#!/usr/bin/env bash

set -euo pipefail

echo "Run system cleanup..."

# Remove preinstalled omarchy apps (webapps, TUIs, bindings)
omarchy-webapp-remove-all
omarchy-tui-remove-all

cp "${HOME}/.config/hypr/bindings.conf" "${HOME}/.config/hypr/bindings.conf.bak"
cp "${HOME}/.local/share/omarchy/default/hypr/plain-bindings.conf" "${HOME}/.config/hypr/bindings.conf"
hyprctl reload

# Drop preinstalled packages (covered by omarchy-remove-preinstalls) and extras
omarchy-pkg-drop \
	aether \
	typora \
	spotify \
	libreoffice-fresh \
	1password-beta \
	1password-cli \
	xournalpp \
	signal-desktop \
	pinta \
	obsidian \
	obs-studio \
	kdenlive \
	lazydocker \
	asdcontrol \
	clang \
	dotnet-runtime-9.0 \
	dust \
	fcitx5 \
	fcitx5-gtk \
	fcitx5-qt \
	github-cli \
	lazygit \
	llvm \
	luarocks \
	mariadb-libs \
	opencode \
	postgresql-libs \
	python-poetry-core \
	ruby \
	slurp \
	tldr \
	tree-sitter-cli \
	wayfreeze \
	whois \
	zoxide

################################################################################

sudo rm -rf "${HOME}/Work" "${HOME}/go" "${HOME}/.cargo" "${HOME}/.npm"

rm -f "${HOME}/.XCompose"
rm -f "${HOME}/.bash_history" "${HOME}/.bash_logout" "${HOME}/.bash_profile"

rm -rf "${HOME}/.config/"{Typora,xournalpp,lazygit,fcitx5}
rm -f "${HOME}/.config/environment.d/fcitx.conf"

# Remove fcitx5 autostart from upstream Omarchy config
sed -i '/exec-once = uwsm-app -- fcitx5/d' "${HOME}/.local/share/omarchy/default/hypr/autostart.conf"

# Disable screensaver on idle (still available via force-launch in system menu)
mkdir -p "${HOME}/.local/state/omarchy/toggles"
touch "${HOME}/.local/state/omarchy/toggles/screensaver-off"

################################################################################

echo "Cleanup finished."
