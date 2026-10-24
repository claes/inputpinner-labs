#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e lon.lock ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
systems_revision=$(cat systems-revision)
nix --version > versions.txt
lon --version >> versions.txt
lon init
lon add github NixOS/nixpkgs nixos-26.05 --revision "$revision"
lon add github nix-systems/default main --name systems --revision "$systems_revision"
