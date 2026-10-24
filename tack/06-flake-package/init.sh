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
# Parent nixpkgs is a source pin; upstream patchelf is a flake pin.
tack add nixpkgs "github:NixOS/nixpkgs/$revision" --fetch
tack add patchelf "github:NixOS/patchelf/$patchelf_revision"
