#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization is deliberate: do not reset an existing experiment's pins.
if [[ -e nix/tamal/manifest.kdl ]]; then
  printf '%s\n' 'Already initialized; use the update instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
nix --version > versions.txt
nixtamal --version >> versions.txt
# Generate the resolver without locking today's default nixpkgs;
# our manifest below selects the comparison's starting commit explicitly.
nixtamal set-up --no-nixpkgs --fetch-time=eval --hash-algorithm=SHA-256

# In Nixtamal 1.5.4, set-up --nixpkgs-revision still locks the branch tip.
# A literal freshness value gives this comparison its exact starting commit.
cat > nix/tamal/manifest.kdl <<EOF
version "1.1.0"
// Evaluation-time fetching lets the shipped resolver supply sources without IFD.
inputs {
    nixpkgs {
        // Bootstrap nixpkgs with built-in fetching, before importing any packages.
        archive fetch-time=eval {
            url "https://github.com/NixOS/nixpkgs/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        // Update target: nixos-26.05; see README.md for branch tracking.
        fresh-cmd {
            \$ echo "$revision"
        }
    }
}
EOF
nixtamal lock nixpkgs
