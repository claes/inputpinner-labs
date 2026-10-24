#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization is deliberate: do not reset an existing experiment's pins.
if [[ -e pin.json ]]; then
  printf '%s\n' 'Already initialized; use the update instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
nix --version > versions.txt
# Compute a real unpacked-tree hash; never substitute a guessed hash.
url="https://github.com/NixOS/nixpkgs/archive/$revision.tar.gz"
hash=$(nix-prefetch-url --unpack "$url")
# Write the complete record only after prefetching has succeeded.
jq -n --arg revision "$revision" --arg url "$url" --arg sha256 "$hash" \
  '{revision: $revision, url: $url, sha256: $sha256}' > pin.json.tmp
mv pin.json.tmp pin.json
