#!/usr/bin/env bash
# Smoke test: stow the dotfiles into a throwaway HOME on macOS and check that
# the basics work. Needs stow, zsh, git, jq and ssh-keygen. Run it from
# anywhere: bash test/smoke.sh
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
export HOME="$T/home"
mkdir -p "$HOME/.ssh/control"
unset XDG_CONFIG_HOME GIT_CONFIG_GLOBAL

fails=0
pass() { printf '  ok    %s\n' "$1"; }
fail() {
    printf '  FAIL  %s\n' "$1"
    fails=$((fails + 1))
}
check() { # description, command...
    local what="$1"
    shift
    if "$@" >/dev/null 2>&1; then pass "$what"; else fail "$what"; fi
}

echo "stow"
(cd "$DOTFILES" && stow --no-folding -t "$HOME" shell git ssh bin agents) &&
    pass "all packages stow into an empty HOME" ||
    fail "all packages stow into an empty HOME"

echo "zsh"
err="$(zsh -l -i -c 'exit' 2>&1 >/dev/null)"
if [[ -z "$err" ]]; then pass "login shell prints nothing to stderr"; else
    fail "login shell prints nothing to stderr"
    printf '%s\n' "$err" | sed 's/^/        /'
fi
check "EDITOR is nvim" test "$(zsh -l -c 'printf %s "$EDITOR"')" = nvim

echo "git"
mkdir -p "$HOME/.config/local"
printf '[user]\n    name = Local Override\n' >"$HOME/.config/local/gitconfig"
check "a local git value overrides the shared one" \
    test "$(git config --global user.name)" = "Local Override"
rm "$HOME/.config/local/gitconfig"

for t in "$DOTFILES"/test/smoke.d/*.sh; do
    [[ -e "$t" ]] || continue
    echo "$(basename "$t" .sh)"
    # shellcheck source=/dev/null
    source "$t"
done

echo
if [[ "$fails" -eq 0 ]]; then echo "all passed"; else echo "$fails failed"; fi
[[ "$fails" -eq 0 ]]
