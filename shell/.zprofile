eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_ANALYTICS=1

# Personal scripts in ~/bin (managed by the bin/ stow package).
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
