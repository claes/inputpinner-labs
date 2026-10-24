#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e .tack/pins.lock.json ]]; then
  printf '%s\n' 'Already initialized; keep experimental updates in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
patchelf_revision=$(cat patchelf-revision)
nix --version > versions.txt
tack --version >> versions.txt
tack init
# Share a flake value: upstream needs nixpkgs.legacyPackages and nixpkgs.lib.
tack add nixpkgs "github:NixOS/nixpkgs/$revision"
tack add patchelf "github:NixOS/patchelf/$patchelf_revision"
# Cover every depth and the aliases used by upstream's follows edges.
sed -i '/^\[all_follow\]/a nixpkgs = ["nixpkgs-lib", "nixpkgs-stable"]' .tack/pins.toml
