#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization is deliberate: do not reset an existing experiment's pins.
if [[ -e nix/sources.json ]]; then
  printf '%s\n' 'Already initialized; use the update instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
nix --version > versions.txt
niv --version >> versions.txt
# Avoid niv's default pins, then add only the dependency this example needs.
niv init --no-nixpkgs
niv add NixOS/nixpkgs --name nixpkgs --branch nixos-26.05 --rev "$revision"
