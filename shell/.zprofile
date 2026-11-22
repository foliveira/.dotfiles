eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_ANALYTICS=1

# Some tools (lazygit on macOS) only read ~/.config when this is set.
export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR=nvim VISUAL=nvim

# Personal scripts in ~/bin (managed by the bin/ stow package).
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
