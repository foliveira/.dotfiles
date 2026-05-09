#!/usr/bin/env bash
# Set HostName / LocalHostName / ComputerName.
# Usage: bash macos/set-hostname.sh "Fabio's MacBook"
set -e

if [[ "$(uname)" != "Darwin" ]]; then
    echo "macOS only." >&2
    exit 1
fi

if [[ $# -ne 1 || -z "$1" ]]; then
    echo "Usage: $0 <name>" >&2
    exit 1
fi

name="$1"
# LocalHostName (Bonjour / .local) only accepts alphanumerics and hyphens.
local_name="$(printf '%s' "$name" | tr ' _' '-' | tr -cd '[:alnum:]-')"

if [[ -z "$local_name" ]]; then
    echo "error: '$name' has no characters valid for a Bonjour LocalHostName." >&2
    exit 1
fi

echo "→ HostName:      $name"
echo "→ LocalHostName: $local_name"
echo "→ ComputerName:  $name"

sudo scutil --set HostName "$name"
sudo scutil --set LocalHostName "$local_name"
sudo scutil --set ComputerName "$name"

dscacheutil -flushcache

echo "Done. Verify with: scutil --get HostName"
