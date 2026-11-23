#!/usr/bin/env bash
# Check that every commit on the main line between two commits is signed by a
# key in an allowed_signers file.
#
# Usage: verify-commits.sh <repo> <from> <to> <allowed_signers>
# Exit status: 0 all signed, 1 some not, 2 the allowed_signers file has no keys.
#
# Only first-parent commits are checked. Merging an agent's branch on a laptop
# with --no-ff (or a squash) makes one laptop-signed commit on the main line,
# and that commit vouches for the branch it brings in. A commit pushed straight
# onto the branch, or a fast-forward onto someone else's commits, fails.
set -uo pipefail

repo="$1" from="$2" to="$3" signers="$4"

if ! grep -qE '^[^#[:space:]]+[[:space:]]+(ssh-|sk-|ecdsa-)' "$signers" 2>/dev/null; then
    exit 2
fi

bad=0
while read -r commit; do
    # ssh-keygen checks the signature. 1Password's op-ssh-sign only signs.
    if ! git -C "$repo" -c gpg.ssh.program=ssh-keygen \
        -c gpg.ssh.allowedSignersFile="$signers" \
        verify-commit "$commit" >/dev/null 2>&1; then
        git -C "$repo" log -1 --format='  not signed by a trusted key: %h %an: %s' "$commit"
        bad=1
    fi
done < <(git -C "$repo" rev-list --first-parent "$from..$to")
exit "$bad"
