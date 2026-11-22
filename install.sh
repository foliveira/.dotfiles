#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PACKAGES=(shell git claude ssh bin)

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

# Back up any pre-existing dotfiles before stow would refuse to overwrite them.
# Walks the full tree per package so nested files (e.g. ~/.claude/settings.json) are also caught.
backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
for pkg in "${PACKAGES[@]}"; do
    [[ -d "$DOTFILES/$pkg" ]] || continue
    while IFS= read -r -d '' src; do
        rel="${src#"$DOTFILES/$pkg/"}"
        target="$HOME/$rel"
        # Regular files, and symlinks that don't point into this repo: stow
        # refuses to replace either.
        if [[ -L "$target" ]]; then
            [[ "$(readlink -f "$target" 2>/dev/null)" == "$DOTFILES/"* ]] && continue
        elif [[ ! -f "$target" ]]; then
            continue
        fi
        mkdir -p "$backup_dir/$(dirname "$rel")"
        log "Backing up $target → $backup_dir/$rel"
        mv "$target" "$backup_dir/$rel"
    done < <(find "$DOTFILES/$pkg" -type f \! -name '.stow-local-ignore' -print0)
done

log "Stowing: ${PACKAGES[*]}"
# --no-folding: stow always creates real directories and only symlinks individual files.
# Without it, an empty target dir (e.g. ~/.config/tmux) would get symlinked wholesale and
# any later writes (like TPM's plugin clones) would land inside the dotfiles repo.
mkdir -p "$HOME/.config" "$HOME/.ssh/control"
chmod 700 "$HOME/.ssh" "$HOME/.ssh/control"
cd "$DOTFILES"
stow -R --no-folding -t "$HOME" "${PACKAGES[@]}"

# Tmux Plugin Manager — clone if missing. Inside tmux, run prefix + I to install plugins.
tpm_dir="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$tpm_dir" ]]; then
    log "Installing TPM (tmux plugin manager)"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
fi

# Catppuccin Mocha for btop and atuin: neither bundles it, so fetch once.
# (bat 0.26 and later ship it.)
fetch_theme() { # tool, destination, url
    command -v "$1" >/dev/null || return 0
    [[ -f "$2" ]] && return 0
    log "Installing Catppuccin Mocha theme for $1"
    mkdir -p "$(dirname "$2")"
    curl -fsSL -o "$2" "$3"
}
fetch_theme btop "$HOME/.config/btop/themes/catppuccin_mocha.theme" \
    https://raw.githubusercontent.com/catppuccin/btop/main/themes/catppuccin_mocha.theme
fetch_theme atuin "$HOME/.config/atuin/themes/catppuccin-mocha-mauve.toml" \
    https://raw.githubusercontent.com/catppuccin/atuin/main/themes/mocha/catppuccin-mocha-mauve.toml

# Catppuccin Mocha (mauve accent) for eza — fetched once. EZA_CONFIG_DIR is
# set in .zshrc so eza reads from this path on macOS too (where its default
# is ~/Library/Application Support/eza).
eza_theme="$HOME/.config/eza/theme.yml"
if [[ ! -f "$eza_theme" ]]; then
    log "Installing Catppuccin Mocha theme for eza"
    mkdir -p "$(dirname "$eza_theme")"
    curl -fsSL -o "$eza_theme" \
        https://raw.githubusercontent.com/catppuccin/eza/main/themes/mocha/catppuccin-mocha-mauve.yml
fi

# Catppuccin colorscheme for nvim — loaded via nvim's native pack/start so
# init.lua's `colorscheme catppuccin-mocha` resolves with no plugin manager.
nvim_catppuccin="$HOME/.local/share/nvim/site/pack/colors/start/catppuccin"
if [[ ! -d "$nvim_catppuccin" ]]; then
    log "Installing Catppuccin colorscheme for neovim"
    git clone --depth 1 https://github.com/catppuccin/nvim "$nvim_catppuccin"
fi

if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    log "Reminder: copy git/gitconfig.local.example → ~/.gitconfig.local and set name/email"
fi

log "Done. Open a new shell, or 'source ~/.zshrc'."
log "macOS defaults: bash $DOTFILES/macos/defaults.sh"
