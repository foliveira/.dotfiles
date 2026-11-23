#!/usr/bin/env bash
# Turn on Touch ID for sudo through /etc/pam.d/sudo_local. macOS Sonoma and
# later keep this file across updates, so run it once.
#
# Inside tmux, pam_tid alone falls back to a password prompt. pam_reattach
# connects sudo to your login session, so the Touch ID dialog shows.
set -e

if [[ "$(uname)" != "Darwin" ]]; then
    echo "macOS only." >&2
    exit 1
fi

if [[ ! -f /etc/pam.d/sudo_local.template ]]; then
    echo "error: macOS 14 (Sonoma) or newer is required." >&2
    exit 1
fi

brew_prefix="$(brew --prefix 2>/dev/null || true)"
if [[ -z "$brew_prefix" ]]; then
    echo "error: brew not found on PATH." >&2
    exit 1
fi

pam_reattach="$brew_prefix/lib/pam/pam_reattach.so"
if [[ ! -f "$pam_reattach" ]]; then
    echo "Installing pam-reattach…"
    brew install pam-reattach
fi

target="/etc/pam.d/sudo_local"
echo "Writing $target…"
sudo tee "$target" >/dev/null <<EOF
# sudo_local — survives system updates. Touch ID for sudo, with pam_reattach
# so the prompt surfaces from inside tmux/screen.
auth       optional       $pam_reattach
auth       sufficient     pam_tid.so
EOF

echo "Done. Test with: sudo -k; sudo whoami"
