# History
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"
setopt EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY
setopt HIST_FIND_NO_DUPS HIST_EXPIRE_DUPS_FIRST SHARE_HISTORY

# Behaviour
setopt AUTO_CD INTERACTIVE_COMMENTS NO_BEEP
bindkey -e

# Homebrew prefix — set by .zprofile via `brew shellenv`. Fall back if running
# zsh in a context where .zprofile didn't run (e.g. some IDE terminals).
brew_prefix="${HOMEBREW_PREFIX:-}"
[[ -z "$brew_prefix" && -d /opt/homebrew ]] && brew_prefix=/opt/homebrew
[[ -z "$brew_prefix" && -d /usr/local/Homebrew ]] && brew_prefix=/usr/local

# zsh-completions — must be on FPATH before compinit runs.
[[ -d "$brew_prefix/share/zsh-completions" ]] && fpath=("$brew_prefix/share/zsh-completions" $fpath)

autoload -Uz compinit && compinit -i
autoload -U colors && colors

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'

# Aliases
alias ll='ls -lah'
alias g='git'
command -v eza >/dev/null && alias ls='eza'
command -v bat >/dev/null && alias cat='bat --paging=never'

# fzf — keybindings (C-t files, C-r history, M-c cd) + completion via fzf --zsh.
if command -v fzf >/dev/null; then
    if command -v fd >/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
    export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border=rounded --info=inline --multi'
    if command -v bat >/dev/null; then
        export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:200 {} 2>/dev/null || eza --tree --color=always --level=2 {} 2>/dev/null'"
    fi
    if command -v eza >/dev/null; then
        export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --level=3 {}'"
    fi
    source <(fzf --zsh)
fi

# zsh-autosuggestions — greys-out a suggested completion based on history.
[[ -f "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting MUST be sourced last among shell extensions.
[[ -f "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Prompt — starship if available, simple fallback otherwise.
if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
else
    PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f %# '
fi

unset brew_prefix

# Machine-local secrets and overrides — never committed.
[[ -f "$HOME/.localrc" ]] && source "$HOME/.localrc"
