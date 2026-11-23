# Sourced by test/smoke.sh. Checks lib/merge-json.sh, which install.sh uses
# for Claude's and pi's settings.

ag_dir="$T/agents"
mkdir -p "$ag_dir"
base="$DOTFILES/agents/claude-settings.json"
target="$ag_dir/settings.json"
# Start as a link, like an old stow install, with a changed key.
jq '.theme = "light"' "$base" >"$ag_dir/linked.json"
ln -s "$ag_dir/linked.json" "$target"

drift="$("$DOTFILES/lib/merge-json.sh" "$base" "$target")"
check "merge: drift report names the changed key" grep -q '^  theme: ' <<<"$drift"
check "merge: a stow link becomes a regular file" test ! -L "$target"

# herdr adds its hooks after the first merge.
jq '.hooks = {"Stop": [{"hooks": [{"type": "command", "command": "herdr-hook"}]}]}' "$target" >"$ag_dir/t" && mv "$ag_dir/t" "$target"
drift="$("$DOTFILES/lib/merge-json.sh" "$base" "$target")"
check "merge: a second run reports no drift" test -z "$drift"
check "merge: herdr's hook is kept once" \
    test "$(jq '[.. | objects | select(.command? == "herdr-hook")] | length' "$target")" = 1
check "merge: every base key is in the result" \
    jq -e --slurpfile b "$base" '. as $t | $b[0] | [paths(scalars)] | all(. as $p | ($t | getpath($p)) == ($b[0] | getpath($p)))' "$target"
