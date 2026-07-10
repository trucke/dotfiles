# Sourced for EVERY zsh invocation (interactive, non-interactive, scripts).
# Keep it to environment only — interactive setup belongs in .zshrc.

export DOTFILES="${HOME}/.dotfiles"

# XDG dirs + tool environment. Sourced here (not .zshrc) so non-interactive
# sessions (ssh <cmd>, scripts, git hooks) get a correct environment too.
source "${DOTFILES}/share/shell/env"

case "$(uname -s)" in
  Darwin)
    export PATH="${XDG_DATA_HOME}/mise/shims:${XDG_DATA_HOME}/pnpm/bin:${HOME}/Library/pnpm/bin:${XDG_BIN_DIR}:/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}"
    ;;
  Linux)
    export PATH="${XDG_DATA_HOME}/mise/shims:${XDG_DATA_HOME}/pnpm/bin:${XDG_BIN_DIR}:${PATH}"
    ;;
esac
