#!/usr/bin/env bash
# Set up this Mac from the dotfiles repo. Safe to run again at any time.
#
# Usage: install.sh [--full | --homelab] [--upgrade]
#   --full     laptops: core, dev and desktop tools (the default)
#   --homelab  the homelab Mac: core and homelab tools
#   --upgrade  also upgrade installed Homebrew packages (`dot upgrade` uses this)
#
# The chosen profile is saved in ~/.config/dotfiles/profile, so later runs
# (and `dot`) use it without the flag.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
STATE_DIR="$HOME/.config/dotfiles"
PROFILE_FILE="$STATE_DIR/profile"

log() { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
die() {
    printf "\033[1;31merror:\033[0m %s\n" "$*" >&2
    exit 1
}

[[ "$(uname)" == "Darwin" ]] || die "these dotfiles are for macOS only."

# --- Options -------------------------------------------------------------

profile=""
upgrade=0
if [[ -f "$PROFILE_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$PROFILE_FILE"
fi
while [[ $# -gt 0 ]]; do
    case "$1" in
    --full) profile=full ;;
    --homelab) profile=homelab ;;
    --upgrade) upgrade=1 ;;
    -h | --help)
        sed -n '2,11p' "$0"
        exit 0
        ;;
    *) die "unknown option: $1" ;;
    esac
    shift
done
profile="${profile:-full}"

case "$profile" in
full)
    BREWFILES=(Brewfile Brewfile.dev Brewfile.desktop)
    PACKAGES=(shell git ssh bin agents)
    ;;
homelab)
    BREWFILES=(Brewfile Brewfile.homelab)
    PACKAGES=(shell git ssh bin)
    ;;
*) die "unknown profile in $PROFILE_FILE: $profile" ;;
esac

mkdir -p "$STATE_DIR"
printf 'profile=%s\n' "$profile" >"$PROFILE_FILE"
log "Profile: $profile"

# --- Homebrew ------------------------------------------------------------

if [[ ! -x /opt/homebrew/bin/brew ]]; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# Plain runs only install what is missing. Upgrades happen on purpose, through
# `dot upgrade`.
if [[ "$upgrade" == 0 ]]; then
    export HOMEBREW_BUNDLE_NO_UPGRADE=1
fi
for brewfile in "${BREWFILES[@]}"; do
    log "brew bundle: $brewfile"
    brew bundle --file="$DOTFILES/$brewfile"
done

# --- Back up files that stow would refuse to replace ----------------------

backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
backup() { # path relative to $HOME
    local rel="$1" target="$HOME/$1"
    if [[ -L "$target" ]]; then
        # A link into this repo is already ours.
        [[ "$(readlink -f "$target" 2>/dev/null)" == "$DOTFILES/"* ]] && return 0
    elif [[ ! -f "$target" ]]; then
        return 0
    fi
    mkdir -p "$backup_dir/$(dirname "$rel")"
    log "Backing up $target → $backup_dir/$rel"
    mv "$target" "$backup_dir/$rel"
}

for pkg in "${PACKAGES[@]}"; do
    while IFS= read -r -d '' src; do
        backup "${src#"$DOTFILES/$pkg/"}"
    done < <(find "$DOTFILES/$pkg" -type f \! -name '.stow-local-ignore' -print0)
done
# tmux reads ~/.tmux.conf before ~/.config/tmux/tmux.conf, so an old one
# would quietly win.
backup .tmux.conf

# --- Stow ----------------------------------------------------------------

# --no-folding makes stow create real directories and link single files.
# Without it, an empty target dir (like ~/.config/tmux) would be linked as a
# whole, and files that tools write later (TPM plugins) would land in the repo.
mkdir -p "$HOME/.config" "$HOME/.ssh/control"
chmod 700 "$HOME/.ssh" "$HOME/.ssh/control"
log "Stowing: ${PACKAGES[*]}"
(cd "$DOTFILES" && stow -R --no-folding -t "$HOME" "${PACKAGES[@]}")

# --- Plugins and themes --------------------------------------------------

tpm_dir="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$tpm_dir" ]]; then
    log "Installing TPM (tmux plugin manager)"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
fi

# Catppuccin Mocha for tools that don't ship it. bat 0.26 and later do.
fetch() { # tool, destination, url
    command -v "$1" >/dev/null || return 0
    [[ -f "$2" ]] && return 0
    log "Downloading $(basename "$2") for $1"
    mkdir -p "$(dirname "$2")"
    curl -fsSL -o "$2" "$3"
}
fetch btop "$HOME/.config/btop/themes/catppuccin_mocha.theme" \
    https://raw.githubusercontent.com/catppuccin/btop/main/themes/catppuccin_mocha.theme
fetch atuin "$HOME/.config/atuin/themes/catppuccin-mocha-mauve.toml" \
    https://raw.githubusercontent.com/catppuccin/atuin/main/themes/mocha/catppuccin-mocha-mauve.toml
# EZA_CONFIG_DIR is set in .zshrc, so eza reads this path on macOS too.
fetch eza "$HOME/.config/eza/theme.yml" \
    https://raw.githubusercontent.com/catppuccin/eza/main/themes/mocha/catppuccin-mocha-mauve.yml

# Catppuccin for nvim, loaded through nvim's own pack/start, no plugin manager.
nvim_catppuccin="$HOME/.local/share/nvim/site/pack/colors/start/catppuccin"
if [[ ! -d "$nvim_catppuccin" ]]; then
    log "Installing the Catppuccin colorscheme for neovim"
    git clone --depth 1 https://github.com/catppuccin/nvim "$nvim_catppuccin"
fi

log "Done. Open a new shell."
if [[ "$profile" == full ]]; then
    log "macOS settings: bash $DOTFILES/macos/defaults.sh"
else
    log "Homelab power settings: bash $DOTFILES/macos/homelab.sh"
fi
