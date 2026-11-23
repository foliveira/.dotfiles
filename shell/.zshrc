# History
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"
setopt EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY
setopt HIST_FIND_NO_DUPS HIST_EXPIRE_DUPS_FIRST SHARE_HISTORY

# Behaviour
setopt AUTO_CD INTERACTIVE_COMMENTS NO_BEEP
bindkey -e

# Homebrew's prefix, set by `brew shellenv` in .zprofile.
brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"

# zsh-completions — must be on FPATH before compinit runs.
[[ -d "$brew_prefix/share/zsh-completions" ]] && fpath=("$brew_prefix/share/zsh-completions" $fpath)

autoload -Uz compinit && compinit -i
autoload -U colors && colors

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'

# Aliases
alias g='git'
alias ts='tailscale'
if command -v eza >/dev/null; then
    alias ls='eza'
    alias ll='eza -lah --git'
    alias la='eza -a'
    alias lt='eza --tree --level=2'
else
    alias ll='ls -lah'
fi
command -v bat >/dev/null && alias cat='bat --paging=never'

# Pick up rg defaults from ripgreprc.
[[ -f "$HOME/.config/ripgrep/ripgreprc" ]] && export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc"

# Tell eza to read theme.yml from ~/.config/eza on macOS too.
[[ -f "$HOME/.config/eza/theme.yml" ]] && export EZA_CONFIG_DIR="$HOME/.config/eza"

# fzf — keybindings (C-t files, C-r history, M-c cd) + completion via fzf --zsh.
if command -v fzf >/dev/null; then
    if command -v fd >/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
    export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border=rounded --info=inline --multi
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
        --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
        --color=selected-bg:#45475a,border:#313244,label:#cdd6f4'
    if command -v bat >/dev/null; then
        export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:200 {} 2>/dev/null || eza --tree --color=always --level=2 {} 2>/dev/null'"
    fi
    if command -v eza >/dev/null; then
        export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --level=3 {}'"
    fi
    source <(fzf --zsh)
fi

# zoxide — smart cd. `z foo` jumps to a frecency-ranked match, `zi` is interactive.
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# direnv — auto-loads .envrc when entering a directory that has one.
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# mise — language version manager. Activates per-project .tool-versions / mise.toml.
command -v mise >/dev/null && eval "$(mise activate zsh)"

# atuin — better history search on Ctrl-R. Up-arrow stays as plain zsh history
# (atuin's up-arrow takeover is intrusive; the picker is the real value).
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

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

# Machine settings from the private config repo: shared, then this machine.
# No secrets there; read them from 1Password when needed (op read, fx).
# ~/.localrc is the old place and goes away once its contents move.
for f in "$HOME/.config/local-shared/env.zsh" "$HOME/.config/local/env.zsh" "$HOME/.localrc"; do
    [[ -f "$f" ]] && source "$f"
done
unset f
