#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e .tack/pins.lock.json ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
stable_revision=$(cat stable-revision)
unstable_revision=$(cat unstable-revision)
nix --version > versions.txt
tack --version >> versions.txt
tack init
tack add stable "github:NixOS/nixpkgs/$stable_revision" --fetch
tack add unstable "github:NixOS/nixpkgs/$unstable_revision" --fetch
# Restore branch targets after locking the reproducible starting commits.
sed -i "s@github:NixOS/nixpkgs/$stable_revision@github:NixOS/nixpkgs/nixos-26.05@" .tack/pins.toml
sed -i "s@github:NixOS/nixpkgs/$unstable_revision@github:NixOS/nixpkgs/nixpkgs-unstable@" .tack/pins.toml
