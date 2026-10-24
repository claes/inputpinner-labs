#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization is deliberate: do not reset an existing experiment's pins.
if [[ -e lock.json ]]; then
  printf '%s\n' 'Already initialized; use the update instructions in README.md.' >&2
  exit 1
fi
nix --version > versions.txt
# Mana has no version flag: retain the immutable tool source instead.
tool_ref=$(cat tool-ref)
printf 'mana source: %s\n' "$tool_ref" >> versions.txt

# upgrade generates just the importer, preserving our small teaching example.
mkdir -p nix
nix run "$tool_ref" -- upgrade
nix run "$tool_ref" -- update
