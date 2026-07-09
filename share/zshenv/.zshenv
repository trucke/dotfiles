export DOTFILES="${HOME}/.dotfiles"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
export XDG_BIN_DIR="${XDG_BIN_DIR:-${HOME}/.local/bin}"

case "$(uname -s)" in
  Darwin)
    export PATH="${XDG_DATA_HOME}/mise/shims:${XDG_DATA_HOME}/pnpm/bin:${HOME}/Library/pnpm/bin:${XDG_BIN_DIR}:/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}"
    ;;
  Linux)
    export PATH="${XDG_DATA_HOME}/mise/shims:${XDG_DATA_HOME}/pnpm/bin:${XDG_BIN_DIR}:${PATH}"
    ;;
esac
