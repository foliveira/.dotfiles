#!/usr/bin/env bash
# Enable Touch ID for sudo via /etc/pam.d/sudo_local. Sonoma+ keeps this file
# across system updates, so this is a one-shot setup. SSH sudo still prompts
# for a password — pam_tid.so falls through when no Touch ID is available.
set -e

if [[ "$(uname)" != "Darwin" ]]; then
    echo "macOS only." >&2
    exit 1
fi

template="/etc/pam.d/sudo_local.template"
target="/etc/pam.d/sudo_local"

if [[ ! -f "$template" ]]; then
    echo "error: $template not found. macOS 14 (Sonoma) or newer is required." >&2
    exit 1
fi

if grep -qE '^auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so' "$target" 2>/dev/null; then
    echo "Touch ID for sudo already enabled."
    exit 0
fi

echo "Writing $target from template…"
sudo cp "$template" "$target"
sudo sed -i '' 's/^#auth/auth/' "$target"

echo "Done. Try 'sudo -k; sudo whoami' — Touch ID should prompt."
