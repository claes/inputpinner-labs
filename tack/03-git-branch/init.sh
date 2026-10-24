#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e .tack/pins.lock.json ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
systems_revision=$(cat systems-revision)
nix --version > versions.txt
tack --version >> versions.txt
tack init
tack add nixpkgs "github:NixOS/nixpkgs/$revision" --fetch
tack add systems "github:nix-systems/default/$systems_revision" --fetch
# Change only the desired update target; retain the commit already in the lock.
sed -i "s@github:nix-systems/default/$systems_revision@github:nix-systems/default/main@" .tack/pins.toml
