#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e pins.json ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
stable_revision=$(cat stable-revision)
unstable_revision=$(cat unstable-revision)
nix --version > versions.txt
# Prefetch immutable archive URLs, never moving branch URLs.
stable_url="https://github.com/NixOS/nixpkgs/archive/$stable_revision.tar.gz"
unstable_url="https://github.com/NixOS/nixpkgs/archive/$unstable_revision.tar.gz"
stable_hash=$(nix-prefetch-url --unpack "$stable_url")
unstable_hash=$(nix-prefetch-url --unpack "$unstable_url")
jq -n --arg sr "$stable_revision" --arg su "$stable_url" --arg sh "$stable_hash" \
  --arg ur "$unstable_revision" --arg uu "$unstable_url" --arg uh "$unstable_hash" \
  '{stable: {branch: "nixos-26.05", revision: $sr, url: $su, sha256: $sh},
    unstable: {branch: "nixpkgs-unstable", revision: $ur, url: $uu, sha256: $uh}}' > pins.json.tmp
mv pins.json.tmp pins.json
