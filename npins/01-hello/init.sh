#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization is deliberate: do not reset an existing experiment's pins.
if [[ -e npins/sources.json ]]; then
  printf '%s\n' 'Already initialized; use the update instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
nix --version > versions.txt
npins --version >> versions.txt
# --bare avoids pinning the tool's default channel as an extra input.
npins init --bare
npins add github NixOS nixpkgs --branch nixos-26.05 --at "$revision"
