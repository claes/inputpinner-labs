#!/usr/bin/env bash
# Compare behavior without initializing or updating any example's pins.
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ ${1:-} == --syntax-only && $# == 1 ]]; then
  while IFS= read -r -d '' expression; do
    nix-instantiate --parse "$expression" > /dev/null
  done < <(find flake niv npins nixtamal tack lon mana manual -type f -name '*.nix' -print0)
  while IFS= read -r -d '' script; do
    bash -n "$script"
  done < <(find . -type f -name '*.sh' -print0)
  printf '%s\n' 'Nix and Bash syntax checks passed (this mode does not initialize or build).'
  exit 0
fi
if [[ $# != 0 ]]; then
  printf '%s\n' 'Usage: ./verify-01.sh [--syntax-only]' >&2
  exit 2
fi

# Report missing generated inputs before trying to evaluate any example.
required=(
  flake/01-hello/flake.lock
  niv/01-hello/nix/sources.json niv/01-hello/nix/sources.nix
  npins/01-hello/npins/sources.json npins/01-hello/npins/default.nix
  nixtamal/01-hello/nix/tamal/default.nix
  nixtamal/01-hello/nix/tamal/lock.json
  tack/01-hello/.tack/pins.lock.json tack/01-hello/.tack/default.nix
  lon/01-hello/lon.lock lon/01-hello/lon.nix
  mana/01-hello/lock.json mana/01-hello/nix/importer.nix mana/01-hello/default.nix
  manual/01-hello/pin.json
)
missing=0
for path in "${required[@]}"; do
  if [[ ! -f $path ]]; then
    printf 'Not initialized: %s\n' "$path" >&2
    missing=1
  fi
done
if [[ $missing == 1 ]]; then
  printf '%s\n' 'Run the init.sh in each example; see its README for prerequisites.' >&2
  exit 2
fi

# The tools use different lock formats; check their revisions before comparing
# package derivations so an accidentally updated input is easy to diagnose.
expected_revision=$(cat manual/01-hello/revision)
locked_revision() {
  case "$1" in
    flake) jq -r '.nodes.nixpkgs.locked.rev' "$2/flake.lock" ;;
    niv) jq -r '.nixpkgs.rev' "$2/nix/sources.json" ;;
    npins) jq -r '.pins.nixpkgs.revision' "$2/npins/sources.json" ;;
    nixtamal) jq -r '.i.nixpkgs.fv' "$2/nix/tamal/lock.json" ;;
    tack) jq -r '.nixpkgs.rev' "$2/.tack/pins.lock.json" ;;
    lon) jq -r '.sources.nixpkgs.revision' "$2/lon.lock" ;;
    mana) jq -r '.sources["/nixpkgs"].locked.rev' "$2/lock.json" ;;
    manual) jq -r '.revision' "$2/pin.json" ;;
  esac
}

system=$(nix eval --impure --raw --expr builtins.currentSystem)
if [[ $system != x86_64-linux ]]; then
  printf 'This comparison has only been prepared for x86_64-linux, got %s.\n' "$system" >&2
  exit 2
fi

# Hash regular files: result symlinks are intentionally excluded.
fingerprint() {
  find "$1" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum
}

baseline=''
for approach in flake niv npins nixtamal tack lon mana manual; do
  example="$approach/01-hello"
  if [[ $(cat "$example/revision") != "$expected_revision" ||
        $(locked_revision "$approach" "$example") != "$expected_revision" ]]; then
    printf 'Starting revision differs: %s\n' "$approach" >&2
    exit 1
  fi
  before=$(fingerprint "$example")
  if [[ $approach == flake ]]; then
    drv=$(cd "$example" && nix eval --raw 'path:.#packages.x86_64-linux.default.drvPath')
    (cd "$example" && nix build path:.)
  else
    attribute=()
    if [[ $approach == mana ]]; then attribute=(-A hello); fi
    drv=$(cd "$example" && nix-instantiate . "${attribute[@]}")
    (cd "$example" && nix-build "${attribute[@]}")
  fi
  greeting=$(LC_ALL=C "$example/result/bin/hello")
  [[ $greeting == 'Hello, world!' ]] || { printf 'Unexpected greeting: %s\n' "$approach" >&2; exit 1; }
  [[ $(fingerprint "$example") == "$before" ]] || { printf 'Build changed files: %s\n' "$approach" >&2; exit 1; }
  if [[ -z $baseline ]]; then baseline=$drv; fi
  [[ $drv == "$baseline" ]] || { printf 'Derivation differs: %s\n%s\n%s\n' "$approach" "$baseline" "$drv" >&2; exit 1; }
  printf '%s: revision, greeting, derivation, and unchanged inputs verified\n' "$approach"
done
