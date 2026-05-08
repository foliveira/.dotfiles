# Apple Silicon vs Intel — first one that exists wins.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

[[ -f "$HOME/.localrc" ]] && source "$HOME/.localrc"
