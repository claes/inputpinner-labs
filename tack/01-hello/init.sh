#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization is deliberate: do not reset an existing experiment's pins.
if [[ -e .tack/pins.lock.json ]]; then
  printf '%s\n' 'Already initialized; use the update instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
nix --version > versions.txt
tack --version >> versions.txt
tack init
# Source-only consumption avoids evaluating nixpkgs's flake outputs.
tack add nixpkgs "github:NixOS/nixpkgs/$revision" --fetch
tack update nixpkgs
