#!/usr/bin/env bash

# Idempotent "re-assert my customizations" path.
# Run on fresh provisioning (via install-dotfiles.sh) and after every
# `omarchy update` (via the post-update hook). Safe to re-run anytime.

set -euo pipefail

DOTFILES="${HOME}/.dotfiles"

# Omarchy's CLIs are added by interactive shell initialization, which is absent
# under SSH commands and update hooks. Keep this script self-contained.
export PATH="${HOME}/.local/share/omarchy/bin:${PATH}"

# Update vendored submodules (tmux-fzf-url, ...)
git -C "${DOTFILES}" submodule update --init --recursive

# Kanshi previously managed display profiles. Omarchy now owns laptop-display
# toggling and recovery, so remove the obsolete service before its package.
systemctl --user disable --now kanshi.service >/dev/null 2>&1 || true
rm -f "${HOME}/.config/systemd/user/kanshi.service"
systemctl --user daemon-reload

# Re-drop Omarchy packages we don't want; upstream migrations may reinstall them.
# omarchy-pkg-drop is a no-op for packages that are already absent.
omarchy-pkg-drop \
	kanshi \
	typora \
	spotify \
	libreoffice-fresh \
	1password-beta \
	1password-cli \
	xournalpp \
	pinta \
	obs-studio \
	opencode \
	kdenlive \
	chromium \
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
	postgresql-libs \
	python-poetry-core \
	tldr \
	wayfreeze \
	whois \
	zoxide

# Remove Omarchy's npx-installed CLI stubs so the repo/AUR agents win in PATH.
rm -f "${HOME}/.local/bin/"{codex,gemini,copilot,ghui,opencode,playwright-cli,pi}

# Re-stow shared + host dotfiles. Some targets are pre-created so stow links the
# files instead of folding the dir (Zed and pi keep runtime state alongside).
mkdir -p "${HOME}/.local/bin" "${HOME}/.ssh" "${HOME}/.config/zed" \
	"${HOME}/.pi/agent/extensions" "${HOME}/.pi/agent/skills" "${HOME}/.pi/agent/themes" \
	"${HOME}/.local/share/applications"
chmod 700 "${HOME}/.ssh"
stow --restow --dir="${DOTFILES}/loki"  --target="${HOME}/.config"    config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.config"    config
stow --restow --dir="${DOTFILES}/share" --target="${HOME}"            zsh
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.local/bin" bin
stow --restow --dir="${DOTFILES}/loki"  --target="${HOME}/.local/bin" bin
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.ssh"       ssh
stow --restow --dir="${DOTFILES}/share" --target="${HOME}/.pi/agent"  pi
bash "${DOTFILES}/share/bin/install-pi-packages"

# Omarchy selects performance on AC/USB-C events. Keep the quieter balanced
# profile through a user service that restores it after each profile change.
systemctl --user daemon-reload
systemctl --user enable balanced-power-profile.service
systemctl --user restart balanced-power-profile.service

# T3Code can replace its protocol-handler desktop symlink with a regular file.
# Remove only a conflicting target so Stow can restore the managed override.
t3code_desktop="${HOME}/.local/share/applications/t3code.desktop"
t3code_source="$(readlink -f "${DOTFILES}/loki/applications/t3code.desktop")"
if [[ -e "${t3code_desktop}" || -L "${t3code_desktop}" ]]; then
	current_source="$(readlink -f "${t3code_desktop}" 2>/dev/null || true)"
	if [[ ! -L "${t3code_desktop}" || "${current_source}" != "${t3code_source}" ]]; then
		rm -f "${t3code_desktop}"
	fi
fi
stow --restow --dir="${DOTFILES}/loki" --target="${HOME}/.local/share/applications" applications
if command -v update-desktop-database &>/dev/null; then
	update-desktop-database "${HOME}/.local/share/applications"
fi

# Deploy Agent Skills to ~/.agents/skills (read natively by codex/cursor/opencode/
# pi) and bridge each into ~/.claude/skills for Claude Code.
env DOTFILES="${DOTFILES}" bash "${DOTFILES}/share/bin/link-agent-skills"

# Install/refresh mise-managed dev tools (mise config was just stowed). On a
# fresh Git bootstrap, initialize jj only after mise has installed it.
if command -v mise &>/dev/null; then
	mise install -y
	if ! mise exec -- jj -R "${DOTFILES}" root &>/dev/null; then
		(
			cd "${DOTFILES}"
			mise exec -- jj git init --git-repo=. .
		)
	fi
	if ! mise exec -- jj -R "${DOTFILES}" bookmark list --tracked main --remote origin 2>/dev/null | grep -q '^main:'; then
		mise exec -- jj -R "${DOTFILES}" bookmark track main --remote=origin
	fi
fi

# Re-deploy Hyprland override files (stow-ignored; they live beside Omarchy's own).
bash "${DOTFILES}/loki/install/install-hypr-overrides.sh"

# Re-assert boot logo (Omarchy updates can reset plymouth).
omarchy-plymouth-set "#1e1e2e" "#cdd6f4" "${DOTFILES}/loki/logo.png"

echo "Sync complete."
