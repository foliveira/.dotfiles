#!/usr/bin/env bash
# Fail if the staged changes add a line that matches the private denylist.
# The denylist lives in the private config repo, so the names it protects never
# appear in this public one. Without it (in CI, say), the check is skipped.
set -euo pipefail

repo_file="$HOME/.config/dotfiles/local-repo"
denylist=""
[[ -f "$repo_file" ]] && denylist="$(cat "$repo_file")/denylist"
if [[ -z "$denylist" || ! -f "$denylist" ]]; then
    echo "denylist: no private denylist found, skipping" >&2
    exit 0
fi

patterns="$(grep -v -e '^#' -e '^[[:space:]]*$' "$denylist" || true)"
[[ -n "$patterns" ]] || exit 0

hits="$(git diff --cached -U0 --no-color |
    grep -e '^+' | grep -v -e '^+++ ' |
    grep -i -E -f <(printf '%s\n' "$patterns") || true)"
if [[ -n "$hits" ]]; then
    echo "denylist: the staged changes add lines with private names:" >&2
    printf '%s\n' "$hits" | sed 's/^/  /' >&2
    exit 1
fi
