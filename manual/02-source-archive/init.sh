#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization must not reset an existing experiment's pins.
if [[ -e pins.json ]]; then
  printf '%s\n' 'Already initialized; use the instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
hello_url="https://ftp.gnu.org/gnu/hello/hello-2.12.3.tar.gz"
nix --version > versions.txt
# fetchTarball expects the unpacked-tree hash, not the archive-byte checksum.
nixpkgs_url="https://github.com/NixOS/nixpkgs/archive/$revision.tar.gz"
nixpkgs_hash=$(nix-prefetch-url --unpack "$nixpkgs_url")
hello_hash=$(nix-prefetch-url --unpack "$hello_url")
jq -n --arg revision "$revision" --arg nixpkgs_url "$nixpkgs_url" \
  --arg nixpkgs_hash "$nixpkgs_hash" --arg hello_url "$hello_url" \
  --arg hello_hash "$hello_hash" \
  '{nixpkgs: {revision: $revision, url: $nixpkgs_url, sha256: $nixpkgs_hash},
    hello: {version: "2.12.3", url: $hello_url, sha256: $hello_hash}}' > pins.json.tmp
mv pins.json.tmp pins.json
