#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e pins.json ]]; then
  printf '%s\n' 'Already initialized; use ./prepare-local.sh and ./build-local.sh.' >&2
  exit 1
fi
revision=$(cat revision)
systems_revision=$(cat systems-revision)
nix --version > versions.txt
nixpkgs_url="https://github.com/NixOS/nixpkgs/archive/$revision.tar.gz"
systems_url="https://github.com/nix-systems/default/archive/$systems_revision.tar.gz"
nixpkgs_hash=$(nix-prefetch-url --unpack "$nixpkgs_url")
systems_hash=$(nix-prefetch-url --unpack "$systems_url")
jq -n --arg revision "$revision" --arg nixpkgs_url "$nixpkgs_url" \
  --arg nixpkgs_hash "$nixpkgs_hash" --arg systems_revision "$systems_revision" \
  --arg systems_url "$systems_url" --arg systems_hash "$systems_hash" \
  '{nixpkgs: {revision: $revision, url: $nixpkgs_url, sha256: $nixpkgs_hash},
    systems: {branch: "main", revision: $systems_revision, url: $systems_url, sha256: $systems_hash}}' > pins.json.tmp
mv pins.json.tmp pins.json
