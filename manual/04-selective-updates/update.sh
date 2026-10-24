#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Name the input explicitly: updating everything would also advance stable.
# Resolve and replace only unstable's entry, preserving stable verbatim.
branch=$(jq -r .unstable.branch pins.json)
revision=$(git ls-remote https://github.com/NixOS/nixpkgs.git "refs/heads/$branch" | cut -f1)
[[ $revision =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Branch lookup did not return a commit.' >&2; exit 1; }
url="https://github.com/NixOS/nixpkgs/archive/$revision.tar.gz"
sha256=$(nix-prefetch-url --unpack "$url")
jq --arg revision "$revision" --arg url "$url" --arg sha256 "$sha256" \
  '.unstable |= (. + {revision: $revision, url: $url, sha256: $sha256})' pins.json > pins.json.tmp
mv pins.json.tmp pins.json
