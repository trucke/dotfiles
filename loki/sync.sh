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

# Re-drop Omarchy packages we don't want; upstream migrations may reinstall them.
# omarchy-pkg-drop is a no-op for packages that are already absent.
omarchy-pkg-drop \
	typora \
	spotify \
	libreoffice-fresh \
	1password-beta \
	1password-cli \
	xournalpp \
	pinta \
	obs-studio \
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
stow --restow --dir="${DOTFILES}/loki"  --target="${HOME}/.local/share/applications" applications

# Deploy Agent Skills to ~/.agents/skills (read natively by codex/cursor/opencode/
# pi) and bridge each into ~/.claude/skills for Claude Code.
env DOTFILES="${DOTFILES}" bash "${DOTFILES}/share/bin/link-agent-skills"

# Install/refresh mise-managed dev tools (mise config was just stowed).
if command -v mise &>/dev/null; then
	mise install -y
fi

# Re-deploy Hyprland override files (stow-ignored; they live beside Omarchy's own).
bash "${DOTFILES}/loki/install/install-hypr-overrides.sh"

# Re-assert boot logo (Omarchy updates can reset plymouth).
omarchy-plymouth-set "#1e1e2e" "#cdd6f4" "${DOTFILES}/loki/logo.png"

echo "Sync complete."
