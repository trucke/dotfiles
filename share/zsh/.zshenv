# Sourced for EVERY zsh invocation (interactive, non-interactive, scripts).
# Keep it to environment only — interactive setup belongs in .zshrc.

export DOTFILES="${HOME}/.dotfiles"

# XDG dirs + tool environment. Sourced here (not .zshrc) so non-interactive
# sessions (ssh <cmd>, scripts, git hooks) get a correct environment too.
source "${DOTFILES}/share/shell/env"

# Homebrew (macOS): sets PATH, HOMEBREW_*, FPATH, MANPATH.
[[ "$OSTYPE" == darwin* && -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# PATH: our dirs first, auto-deduped (typeset -U). Missing dirs are harmless.
typeset -U path PATH
path=(
  "${XDG_DATA_HOME}/mise/shims"
  "${XDG_DATA_HOME}/pnpm/bin"
  "${HOME}/Library/pnpm/bin"
  "${CARGO_HOME}/bin"
  "${XDG_DATA_HOME}/bin"
  "${DOTFILES}/share/bin"
  "${XDG_CACHE_HOME}/.bun/bin"
  "${XDG_BIN_DIR}"
  $path
)
