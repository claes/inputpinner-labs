#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e pins.json ]]; then
  printf '%s\n' 'Already initialized; keep experimental updates in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
patchelf_revision=$(cat patchelf-revision)
compat_revision=$(cat flake-compat-revision)
nix --version > versions.txt
# Hash unpacked source trees, not compressed archives.
nixpkgs_url="https://github.com/NixOS/nixpkgs/archive/$revision.tar.gz"
patchelf_url="https://github.com/NixOS/patchelf/archive/$patchelf_revision.tar.gz"
compat_url="https://github.com/NixOS/flake-compat/archive/$compat_revision.tar.gz"
nixpkgs_hash=$(nix-prefetch-url --unpack "$nixpkgs_url")
patchelf_hash=$(nix-prefetch-url --unpack "$patchelf_url")
compat_hash=$(nix-prefetch-url --unpack "$compat_url")
jq -n --arg nr "$revision" --arg nu "$nixpkgs_url" --arg nh "$nixpkgs_hash" \
  --arg pr "$patchelf_revision" --arg pu "$patchelf_url" --arg ph "$patchelf_hash" \
  --arg cr "$compat_revision" --arg cu "$compat_url" --arg ch "$compat_hash" \
  '{nixpkgs: {revision: $nr, url: $nu, sha256: $nh},
    patchelf: {revision: $pr, url: $pu, sha256: $ph},
    "flake-compat": {revision: $cr, url: $cu, sha256: $ch}}' > pins.json.tmp
mv pins.json.tmp pins.json
