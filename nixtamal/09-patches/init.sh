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
# Declare our selected commits explicitly instead of locking today's default nixpkgs.
nixtamal set-up --no-nixpkgs --fetch-time=eval --hash-algorithm=SHA-256
cat > nix/tamal/manifest.kdl <<EOF
version "1.1.0"
// Evaluation-time fetching lets the shipped resolver supply sources without IFD.
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
        // Fixed fixtures make the patch-failure demonstration repeatable.
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
