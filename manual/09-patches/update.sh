#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# This is a reproducible source update, not a patch repair.
target=$(cat updated-systems-revision)
[[ $target =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Invalid fixture revision.' >&2; exit 1; }
# Recompute only the selected archive's hash; retain the nixpkgs entry.
url="https://github.com/nix-systems/default/archive/$target.tar.gz"
sha256=$(nix-prefetch-url --unpack "$url")
jq --arg revision "$target" --arg url "$url" --arg sha256 "$sha256" \
  '.systems |= (. + {revision: $revision, url: $url, sha256: $sha256})' pins.json > pins.json.tmp
mv pins.json.tmp pins.json
