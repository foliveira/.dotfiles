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

# fzf integration (installed by `$(brew --prefix)/opt/fzf/install`)
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

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
