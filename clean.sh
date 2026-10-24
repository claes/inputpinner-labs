#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
if [[ $# != 0 ]]; then
  printf '%s\n' 'Usage: ./clean.sh' >&2
  exit 2
fi

# Only visit real numbered example directories; never follow source symlinks.
for approach in flake niv npins nixtamal tack lon mana manual; do
  [[ -d "$project_dir/$approach" && ! -L "$project_dir/$approach" ]] || continue
  for example in "$project_dir/$approach"/[0-9][0-9]-*; do
    [[ -d "$example" && ! -L "$example" ]] || continue

    # Unlink build outputs without touching their targets in the Nix store.
    # Abandoned *.tmp files and Mana's staged next lock are also disposable.
    # Local development checkouts are source, including any *.tmp files in them.
    find "$example" ! -path "$example/local-systems/*" \
      \( -type l \( -name result -o -name 'result-*' \) \
      -o -type f \( -name '*.tmp' -o -name next_lock.json \) \) \
      -print -delete
  done
done
