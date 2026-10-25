#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e nix/tamal/manifest.kdl ]]; then
  printf '%s\n' 'Already initialized; use a disposable copy for experiments.' >&2
  exit 1
fi
nix --version > versions.txt
nixtamal --version >> versions.txt
# The native loader needs records with outPath, not evaluation-time path strings.
# Reading these build-time sources requires IFD during normal evaluation.
nixtamal set-up --no-nixpkgs --fetch-time=build --hash-algorithm=SHA-256
cat > nix/tamal/manifest.kdl <<EOF
version "1.1.0"
// Build-time fetchers expose outPath records required by the native with-inputs loader.
// Importing their Nix files requires IFD.
inputs {
    nixpkgs {
        archive fetch-time=build {
            url "https://github.com/NixOS/nixpkgs/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        fresh-cmd {
            \$ echo "$(cat revision)"
        }
    }
    patchelf {
        archive fetch-time=build {
            url "https://github.com/NixOS/patchelf/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        fresh-cmd {
            \$ echo "$(cat patchelf-revision)"
        }
    }
    with-inputs {
        archive fetch-time=build {
            url "https://github.com/denful/with-inputs/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        fresh-cmd {
            \$ echo "$(cat with-inputs-revision)"
        }
    }
    upstream-nixpkgs {
        archive fetch-time=build {
            url "https://github.com/NixOS/nixpkgs/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        fresh-cmd {
            \$ echo "$(cat upstream-nixpkgs-revision)"
        }
    }
}
EOF
nixtamal lock --no-tui
