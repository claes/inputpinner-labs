#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e lon.lock ]]; then
  printf '%s\n' 'Already initialized; use a disposable copy for experiments.' >&2
  exit 1
fi
nix --version > versions.txt
lon --version >> versions.txt
lon init
lon add github NixOS/nixpkgs nixos-26.05 --name nixpkgs --revision "$(cat revision)"
lon add github NixOS/patchelf master --name patchelf --revision "$(cat patchelf-revision)"
lon add github denful/with-inputs main --name with-inputs --revision "$(cat with-inputs-revision)"
lon add github hercules-ci/flake-parts main --name flake-parts --revision "$(cat flake-parts-revision)"
lon add github cachix/git-hooks.nix master --name git-hooks-nix --revision "$(cat git-hooks-nix-revision)"
