source "${HOME}/.dotfiles/shell/env"
# --------------------------------------------------------------------
# Download Zinit, if it's not there yet
# --------------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"
if command -v brew &> /dev/null; then
    if [[ -f "/opt/homebrew/bin/brew" ]] then
        # If you're using macOS, you'll want this enabled
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# --------------------------------------------------------------------
# History
# --------------------------------------------------------------------
HISTSIZE=5000
HISTFILE="${XDG_DATA_HOME}/zsh/zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
if [[ ! -f "${HISTFILE}" ]]; then
    mkdir -p $(dirname "${HISTFILE}") && touch "${HISTFILE}"
    chmod 644 "${HISTFILE}"
fi

# --------------------------------------------------------------------
# zinit configuration and setup
# --------------------------------------------------------------------
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit snippet OMZP::command-not-found

zstyle ':completion:*' dump-file "${XDG_CACHE_HOME}/zsh/.zcompdump"
zstyle ":completion:*" matcher-list "m:{a-z}={A-Za-z}"
zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"
zstyle ":completion:*" menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# Load completions
autoload -Uz compinit && compinit -C -d "${ZSH_COMPDUMP}"

# --------------------------------------------------------------------
# Keybindings
# --------------------------------------------------------------------
bindkey -s ^f "tmux-sessionizer\n"
bindkey -s '\eh' "tmux-sessionizer -s 0\n"
bindkey -s '\ej' "tmux-sessionizer -s 1\n"
bindkey -s '\ek' "tmux-sessionizer -s 2\n"
bindkey -s '\el' "tmux-sessionizer -s 3\n"

# --------------------------------------------------------------------
# Setup PATH
# --------------------------------------------------------------------
function prepend-path() {
  [[ -d "$1" ]] && PATH="$1:${PATH}"
}

type getconf > /dev/null 2>&1 && PATH=$($(command -v getconf) PATH)
# prepend new items to path (if directory exists)
prepend-path "/bin"
prepend-path "/usr/bin"
if [[ -f "/opt/homebrew/bin/brew" ]] then
    brew_prefix=$(/opt/homebrew/bin/brew --prefix)
    prepend-path "${brew_prefix}/sbin"
    prepend-path "${brew_prefix}/bin"
fi
prepend-path "/usr/local/bin"
prepend-path "${CARGO_HOME}/bin"
prepend-path "${XDG_DATA_HOME}/bin"
prepend-path "/sbin"
prepend-path "/usr/sbin"
prepend-path "${HOME}/.opencode/bin"
prepend-path "${HOME}/.local/scripts"
prepend-path "${HOME}/.local/bin"
prepend-path "${HOME}/.local/tmux-sessionizer"
prepend-path "${GHOSTTY_BIN_DIR}"
# Remove duplicates (preserving prepended items)
# Source: http://unix.stackexchange.com/a/40755
PATH=$(echo -n "${PATH}" | awk -v RS=: '{ if (!arr[$0]++) {printf("%s%s",!ln++?"":":",$0)}}')
# Wrap up
export PATH

# --------------------------------------------------------------------
# Source shell file
# --------------------------------------------------------------------
source "${HOME}/.dotfiles/shell/aliases"
source "${HOME}/.dotfiles/shell/functions"
source "${HOME}/.dotfiles/shell/init"

