#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(shell git)

log() { printf "\033[1;34m==>\033[0m %s\n" "$*"; }

if [[ "$(uname)" != "Darwin" ]]; then
    log "Warning: this installer targets macOS. Brew/Brewfile steps will likely fail elsewhere."
fi

if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Brew was just installed and isn't on PATH yet for the rest of this script.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v stow >/dev/null 2>&1; then
    log "Installing stow"
    brew install stow
fi

if [[ -f "$DOTFILES/Brewfile" ]]; then
    log "Installing Brewfile"
    brew bundle --file="$DOTFILES/Brewfile"
fi

# Back up any pre-existing top-level dotfiles before stow would refuse to overwrite them.
# Only handles depth-1 files per package — nested conflicts surface as stow errors.
backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
for pkg in "${PACKAGES[@]}"; do
    [[ -d "$DOTFILES/$pkg" ]] || continue
    while IFS= read -r -d '' src; do
        target="$HOME/$(basename "$src")"
        if [[ -f "$target" && ! -L "$target" ]]; then
            mkdir -p "$backup_dir"
            log "Backing up $target → $backup_dir/"
            mv "$target" "$backup_dir/"
        fi
    done < <(find "$DOTFILES/$pkg" -maxdepth 1 -type f -print0)
done

log "Stowing: ${PACKAGES[*]}"
# --no-folding: stow always creates real directories and only symlinks individual files.
# Without it, an empty target dir (e.g. ~/.config/tmux) would get symlinked wholesale and
# any later writes (like TPM's plugin clones) would land inside the dotfiles repo.
mkdir -p "$HOME/.config"
cd "$DOTFILES"
stow -R --no-folding -t "$HOME" "${PACKAGES[@]}"

# Tmux Plugin Manager — clone if missing. Inside tmux, run prefix + I to install plugins.
tpm_dir="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$tpm_dir" ]]; then
    log "Installing TPM (tmux plugin manager)"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
fi

if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    log "Reminder: copy git/gitconfig.local.example → ~/.gitconfig.local and set name/email"
fi

log "Done. Open a new shell, or 'source ~/.zshrc'."
log "macOS defaults: bash $DOTFILES/macos/defaults.sh"
