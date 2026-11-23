# shellcheck shell=bash
# Sourced by test/smoke.sh. Signs commits with a throwaway key and checks
# lib/verify-commits.sh, which `dot` uses before applying the repo.

sig_dir="$T/signing"
mkdir -p "$sig_dir/keys"
eval "$(ssh-agent -a "$sig_dir/agent.sock" -s)" >/dev/null
for k in laptop agent; do
    ssh-keygen -q -t ed25519 -N '' -C "$k" -f "$sig_dir/keys/$k"
    SSH_AUTH_SOCK="$sig_dir/agent.sock" ssh-add -q "$sig_dir/keys/$k"
done
printf 'smoke@example.invalid %s\n' "$(cat "$sig_dir/keys/laptop.pub")" >"$sig_dir/allowed"
: >"$sig_dir/empty"

sig_git() { # key, git args...
    local key="$1"
    shift
    SSH_AUTH_SOCK="$sig_dir/agent.sock" git -C "$sig_dir/repo" \
        -c user.name=Smoke -c user.email=smoke@example.invalid \
        -c gpg.format=ssh -c gpg.ssh.program=ssh-keygen -c commit.gpgsign=true \
        -c user.signingkey="key::$(cat "$sig_dir/keys/$key.pub")" "$@"
}
verify() { "$DOTFILES/lib/verify-commits.sh" "$sig_dir/repo" "$1" "$2" "${3:-$sig_dir/allowed}" >/dev/null; }

git init -q -b master "$sig_dir/repo"
sig_git laptop commit -q --allow-empty -m base
base="$(git -C "$sig_dir/repo" rev-parse HEAD)"
sig_git laptop switch -q -c feature
sig_git agent commit -q --allow-empty -m "agent work"
sig_git laptop switch -q master
sig_git laptop merge -q --no-ff -m "merge feature" feature
check "a commit is signed through the agent" \
    git -C "$sig_dir/repo" -c gpg.ssh.allowedSignersFile="$sig_dir/allowed" verify-commit HEAD
check "a laptop-signed merge of agent commits passes" verify "$base" master

merged="$(git -C "$sig_dir/repo" rev-parse HEAD)"
sig_git agent commit -q --allow-empty -m "agent on master"
if verify "$merged" master; then fail "an agent commit on master is refused"; else pass "an agent commit on master is refused"; fi
git -C "$sig_dir/repo" reset -q --hard "$base"
git -C "$sig_dir/repo" merge -q --ff-only feature
if verify "$base" master; then fail "a fast-forward onto agent commits is refused"; else pass "a fast-forward onto agent commits is refused"; fi
verify "$base" master "$sig_dir/empty"
check "an empty allowed_signers file reports 2 (not set up)" test "$?" = 2

SSH_AUTH_SOCK="$sig_dir/agent.sock" ssh-agent -k >/dev/null
