#!/usr/bin/env bash
set -euo pipefail

# Niri's output config has no catch-all selector. Discover current connectors
# through its IPC and apply 1:1 scale at session startup (or when run manually).
outputs=''
for _ in 1 2 3 4 5; do
    if outputs=$(niri msg -j outputs 2>/dev/null); then
        break
    fi
    sleep 1
done
[[ -n "$outputs" ]] || exit 1

while IFS= read -r connector; do
    if [[ "${1:-}" == --dry-run ]]; then
        printf 'niri msg output %q scale 1.0\n' "$connector"
    else
        niri msg output "$connector" scale 1.0
    fi
done < <(jq -r 'keys[]' <<< "$outputs")
