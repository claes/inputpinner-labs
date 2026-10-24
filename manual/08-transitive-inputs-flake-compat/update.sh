#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Select a fixed alternate parent pin; both packages must follow it.
target=$(cat alternate-revision)
[[ $target =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Invalid alternate revision.' >&2; exit 1; }
url="https://github.com/NixOS/nixpkgs/archive/$target.tar.gz"
sha256=$(nix-prefetch-url --unpack "$url")
jq --arg revision "$target" --arg url "$url" --arg sha256 "$sha256" \
  '.nixpkgs = {revision: $revision, url: $url, sha256: $sha256}' pins.json > pins.json.tmp
mv pins.json.tmp pins.json
