#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e nix/tamal/manifest.kdl ]]; then
  printf '%s\n' 'Already initialized; keep experimental updates in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
patchelf_revision=$(cat patchelf-revision)
adapter_revision=$(cat flake-inputs-revision)
nix --version > versions.txt
nixtamal --version >> versions.txt
# Declare our selected commits explicitly instead of locking today's default nixpkgs.
nixtamal set-up --no-nixpkgs --fetch-time=eval --hash-algorithm=SHA-256
# Explicit freshness values reproduce these selected commits during setup.
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
    patchelf {
        archive fetch-time=eval {
            url "https://github.com/NixOS/patchelf/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        fresh-cmd {
            \$ echo "$patchelf_revision"
        }
    }
    flake-inputs {
        archive fetch-time=eval {
            url "https://github.com/fricklerhandwerk/flake-inputs/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        fresh-cmd {
            \$ echo "$adapter_revision"
        }
    }
}
EOF
nixtamal lock --no-tui
