#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e lock.json ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
systems_revision=$(cat systems-revision)
nix --version > versions.txt
tool_ref=$(cat tool-ref)
printf 'mana source: %s\n' "$tool_ref" >> versions.txt
mkdir -p nix
nix run "$tool_ref" -- upgrade
# Select the initial fixture explicitly; update.sh later selects the second one.
sed -i 's@github:nix-systems/default/[^"]*@github:nix-systems/default/'"$systems_revision"'@' mana.nix
nix run "$tool_ref" -- update
