#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e lock.json ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
stable_revision=$(cat stable-revision)
unstable_revision=$(cat unstable-revision)
nix --version > versions.txt
tool_ref=$(cat tool-ref)
printf 'mana source: %s\n' "$tool_ref" >> versions.txt
mkdir -p nix
nix run "$tool_ref" -- upgrade
# Mana has no CLI seed override; restore the manifest after generating its lock.
cp mana.nix mana.nix.tmp
trap 'mv -- mana.nix.tmp mana.nix' EXIT
sed -i "s@github:NixOS/nixpkgs/nixos-26.05@github:NixOS/nixpkgs/$stable_revision@" mana.nix
sed -i "s@github:NixOS/nixpkgs/nixpkgs-unstable@github:NixOS/nixpkgs/$unstable_revision@" mana.nix
nix run "$tool_ref" -- update
mv -- mana.nix.tmp mana.nix
trap - EXIT
