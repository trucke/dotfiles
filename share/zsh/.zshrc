# --------------------------------------------------------------------
# Zinit
# --------------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# --------------------------------------------------------------------
# History
# --------------------------------------------------------------------
HISTSIZE=5000
HISTFILE="${XDG_DATA_HOME}/zsh/zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space \
  hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_find_no_dups
mkdir -p "${HISTFILE:h}"

# --------------------------------------------------------------------
# Plugins + completions
# --------------------------------------------------------------------
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zinit snippet OMZP::command-not-found

zstyle ':completion:*' dump-file "${XDG_CACHE_HOME}/zsh/.zcompdump"
zstyle ":completion:*" matcher-list "m:{a-z}={A-Za-z}"
zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"
zstyle ":completion:*" menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

autoload -Uz compinit && compinit -C -d "${ZSH_COMPDUMP}"
zinit cdreplay -q

# --------------------------------------------------------------------
# Keybindings
# --------------------------------------------------------------------
[[ -o interactive && -t 0 ]] && bindkey -s ^f "tmux-sessionizer\n"

# --------------------------------------------------------------------
# Shell fragments
# --------------------------------------------------------------------
source "${DOTFILES}/share/shell/aliases"
source "${DOTFILES}/share/shell/functions"
source "${DOTFILES}/share/shell/init"
