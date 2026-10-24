#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e nix/tamal/manifest.kdl ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
systems_revision=$(cat systems-revision)
nix --version > versions.txt
nixtamal --version >> versions.txt
nixtamal set-up --no-nixpkgs --fetch-time=eval --hash-algorithm=SHA-256
cat > nix/tamal/manifest.kdl <<EOF
version "1.1.0"
inputs {
    nixpkgs {
        archive fetch-time=eval {
            url "https://github.com/NixOS/nixpkgs/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        fresh-cmd {
            \$ echo "$revision"
        }
    }
    systems {
        // Resolve main to a commit, then fetch that immutable archive.
        archive fetch-time=eval {
            url "https://github.com/nix-systems/default/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        fresh-cmd {
            \$ echo "$systems_revision"
        }
    }
}
EOF
nixtamal lock --no-tui
# The lock now holds the historical commit; future refreshes should follow main.
sed -i 's@\$ echo "'"$systems_revision"'"@$ git ls-remote "https://github.com/nix-systems/default.git" --refs "refs/heads/main"\n            | cut -f1@' nix/tamal/manifest.kdl
