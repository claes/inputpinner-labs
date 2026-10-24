#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization is deliberate: do not reset an existing experiment's pins.
if [[ -e lon.lock ]]; then
  printf '%s\n' 'Already initialized; use the update instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
nix --version > versions.txt
lon --version >> versions.txt
lon init
# Select the initial commit independently of the branch used for updates.
lon add github NixOS/nixpkgs nixos-26.05 --revision "$revision"
