#!/usr/bin/env bash
# Merge a base JSON file from this repo into a settings file on this Mac.
# Usage: merge-json.sh <base.json> <target.json>
#
# Keys in the base win. Keys only the target has (like herdr's hooks) stay.
# Before writing, it prints each base key whose value on this Mac is different,
# so a change made in the app can be copied back into the repo.
set -euo pipefail

base="$1"
target="$2"

mkdir -p "$(dirname "$target")"
# An old stow link would make jq write into the repo. Replace it with a copy.
if [[ -L "$target" ]]; then
    cp "$target" "$target.tmp"
    rm "$target"
    mv "$target.tmp" "$target"
fi
[[ -s "$target" ]] || echo '{}' >"$target"

jq -r --slurpfile base "$base" '
  def leafpaths:
    if type == "object" then
      keys_unsorted[] as $k | (.[$k] | leafpaths) as $p | [$k] + $p
    else [] end;
  . as $machine
  | $base[0] | leafpaths as $p
  | ($machine | try getpath($p) catch null) as $m
  | select($m != null and $m != ($base[0] | getpath($p)))
  | "  \($p | join(".")): this Mac has \($m | tojson), the repo has \($base[0] | getpath($p) | tojson)"
' "$target" | {
    if IFS= read -r first; then
        echo "Settings in $target that differ from $(basename "$base") (the repo wins):"
        printf '%s\n' "$first"
        cat
    fi
}

tmp="$(mktemp "$target.XXXXXX")"
jq --slurpfile base "$base" '. * $base[0]' "$target" >"$tmp"
chmod 600 "$tmp"
mv "$tmp" "$target"
