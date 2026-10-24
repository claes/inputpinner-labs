#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e nix/tamal/manifest.kdl ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
stable_revision=$(cat stable-revision)
unstable_revision=$(cat unstable-revision)
nix --version > versions.txt
nixtamal --version >> versions.txt
nixtamal set-up --no-nixpkgs --fetch-time=eval --hash-algorithm=SHA-256
# Seed explicit commits; set-up's default nixpkgs selection is not used.
cat > nix/tamal/manifest.kdl <<EOF
version "1.1.0"
inputs {
    stable {
        archive fetch-time=eval {
            url "https://github.com/NixOS/nixpkgs/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        fresh-cmd {
            \$ echo "$stable_revision"
        }
    }
    unstable {
        archive fetch-time=eval {
            url "https://github.com/NixOS/nixpkgs/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        fresh-cmd {
            \$ echo "$unstable_revision"
        }
    }
}
EOF
nixtamal lock --no-tui
# Only refresh commands consult branches; ordinary evaluation reads the lock.
sed -i 's@\$ echo "'"$stable_revision"'"@$ git ls-remote "https://github.com/NixOS/nixpkgs.git" --refs "refs/heads/nixos-26.05"\n            | cut -f1@' nix/tamal/manifest.kdl
sed -i 's@\$ echo "'"$unstable_revision"'"@$ git ls-remote "https://github.com/NixOS/nixpkgs.git" --refs "refs/heads/nixpkgs-unstable"\n            | cut -f1@' nix/tamal/manifest.kdl
