#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization must not reset an existing experiment's pins.
if [[ -e nix/tamal/manifest.kdl ]]; then
  printf '%s\n' 'Already initialized; use the instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
hello_url="https://ftp.gnu.org/gnu/hello/hello-2.12.3.tar.gz"
nix --version > versions.txt
nixtamal --version >> versions.txt
# Generate only the resolver; declare both archive inputs explicitly below.
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
    hello {
        // A fixed release URL and its unpacked-tree hash pin the source.
        archive fetch-time=eval {
            url "$hello_url"
        }
        hash algorithm=SHA-256
    }
}
EOF
nixtamal lock --no-tui
