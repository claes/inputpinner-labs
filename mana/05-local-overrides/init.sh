#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e lock.json ]]; then
  printf '%s\n' 'Already initialized; use ./prepare-local.sh and ./build-local.sh.' >&2
  exit 1
fi
systems_revision=$(cat systems-revision)
nix --version > versions.txt
tool_ref=$(cat tool-ref)
printf 'mana source: %s\n' "$tool_ref" >> versions.txt
mkdir -p nix
nix run "$tool_ref" -- upgrade
# Mana has no CLI revision override. Temporarily select the seed commit,
# generate the native lock, then restore the branch-tracking manifest.
cp mana.nix mana.nix.tmp
trap 'mv -- mana.nix.tmp mana.nix' EXIT
sed -i "s@github:nix-systems/default/main@github:nix-systems/default/$systems_revision@" mana.nix
nix run "$tool_ref" -- update
mv -- mana.nix.tmp mana.nix
trap - EXIT
