#!/usr/bin/env bash
# Power settings for the homelab Mac: never sleep, and start again by itself
# after a power cut. Run once; needs sudo.
set -euo pipefail

[[ "$(uname)" == "Darwin" ]] || {
    echo "macOS only." >&2
    exit 1
}

sudo pmset -a sleep 0 disksleep 0 autorestart 1
pmset -g | grep -E '^ *(sleep|disksleep|autorestart) '
