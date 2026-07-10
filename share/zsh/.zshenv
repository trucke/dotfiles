# Sourced for EVERY zsh invocation (interactive, non-interactive, scripts).
# Keep it to environment only — interactive setup belongs in .zshrc.

export DOTFILES="${HOME}/.dotfiles"

# XDG dirs + tool environment. Sourced here (not .zshrc) so non-interactive
# sessions (ssh <cmd>, scripts, git hooks) get a correct environment too.
source "${DOTFILES}/share/shell/env"

# PATH + Homebrew. Lives in share/shell/path because .zshrc re-sources it to
# undo macOS path_helper's PATH reordering on login shells (see that file).
source "${DOTFILES}/share/shell/path"
