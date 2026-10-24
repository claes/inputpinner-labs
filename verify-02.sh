#!/usr/bin/env bash
# Verify the separately pinned archive as well as the resulting package.
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ ${1:-} == --syntax-only && $# == 1 ]]; then
  for approach in flake niv npins lon nixtamal tack mana manual; do
    while IFS= read -r -d '' expression; do
      nix-instantiate --parse "$expression" > /dev/null
    done < <(find "$approach/02-source-archive" -type f -name '*.nix' -print0)
    bash -n "$approach/02-source-archive/init.sh"
  done
  bash -n "$0"
  printf '%s\n' 'Example 02 Nix and Bash syntax checks passed.'
  exit 0
fi
if [[ $# != 0 ]]; then
  printf '%s\n' 'Usage: ./verify-02.sh [--syntax-only]' >&2
  exit 2
fi

system=$(nix eval --impure --raw --expr builtins.currentSystem)
if [[ $system != x86_64-linux ]]; then
  printf 'This check targets x86_64-linux; got %s.\n' "$system" >&2
  exit 2
fi

# Read the two independently locked inputs in each tool's native format.
locked_inputs() {
  case "$1" in
    flake) jq -r '[.nodes.nixpkgs.locked.rev, .nodes.hello.locked.url][]' "$2/flake.lock" ;;
    niv) jq -r '[.nixpkgs.rev, .hello.url][]' "$2/nix/sources.json" ;;
    npins) jq -r '[.pins.nixpkgs.revision, .pins.hello.url][]' "$2/npins/sources.json" ;;
    lon) jq -r '[.sources.nixpkgs.revision, .sources.hello.url][]' "$2/lon.lock" ;;
    nixtamal) jq -r '[.i.nixpkgs.fv, .i.hello.kd[1].ur][]' "$2/nix/tamal/lock.json" ;;
    tack) jq -r '[.nixpkgs.rev, .hello.url][]' "$2/.tack/pins.lock.json" ;;
    mana) jq -r '[.sources["/nixpkgs"].locked.rev, .sources["/hello"].args.url][]' "$2/lock.json" ;;
    manual) jq -r '[.nixpkgs.revision, .hello.url][]' "$2/pins.json" ;;
  esac
}

# Resolve the source independently of the package expression. This catches an
# accidental return of pkgs.hello without the source override.
source_expression() {
  case "$1" in
    flake) printf '%s' 'let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in builtins.fetchTree (builtins.removeAttrs lock.nodes.hello.locked [ "lastModified" ])' ;;
    niv) printf '%s' '(import ./nix/sources.nix {}).hello' ;;
    npins) printf '%s' '(import ./npins).hello' ;;
    lon) printf '%s' '(import ./lon.nix).hello' ;;
    nixtamal) printf '%s' '(import ./nix/tamal {}).hello' ;;
    tack) printf '%s' '(import ./.tack).hello' ;;
    mana) printf '%s' 'let lock = builtins.fromJSON (builtins.readFile ./lock.json); pin = lock.sources."/hello"; in builtins.fetchTree (pin.args // builtins.removeAttrs pin.locked [ "lastModified" "lastModifiedDate" "shortRev" ])' ;;
    manual) printf '%s' 'let pins = builtins.fromJSON (builtins.readFile ./pins.json); in builtins.fetchTarball { inherit (pins.hello) url sha256; }' ;;
  esac
}

fingerprint() {
  find "$1" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum
}

expected_revision=$(cat manual/02-source-archive/revision)
expected_url=https://ftp.gnu.org/gnu/hello/hello-2.12.3.tar.gz
expected_hash=$(nix hash convert --hash-algo sha256 --to sri \
  "$(jq -r .hello.sha256 manual/02-source-archive/pins.json)")

for approach in flake niv npins lon nixtamal tack mana manual; do
  example="$approach/02-source-archive"
  expected_inputs=$(printf '%s\n%s' "$expected_revision" "$expected_url")
  [[ $(cat "$example/revision") == "$expected_revision" &&
     $(locked_inputs "$approach" "$example") == "$expected_inputs" ]] || {
    printf 'Locked inputs differ: %s\n' "$approach" >&2; exit 1;
  }
  before=$(fingerprint "$example")
  if [[ $approach == flake ]]; then
    (cd "$example" && nix build path:.)
  elif [[ $approach == mana ]]; then
    package='(import ./. {}).hello'
    (cd "$example" && nix-build -A hello)
  else
    package='(import ./. {})'
    (cd "$example" && nix-build)
  fi

  if [[ $approach == flake ]]; then
    # Let the CLI resolve path:. so project paths containing spaces work too.
    actual_source=$(cd "$example" && nix eval --raw 'path:.#packages.x86_64-linux.default.src.outPath')
    drv=$(cd "$example" && nix eval --raw 'path:.#packages.x86_64-linux.default.drvPath')
  else
    actual_source=$(cd "$example" && nix eval --impure --raw --expr "builtins.toString ($package.src)")
    drv=$(cd "$example" && nix eval --impure --raw --expr "$package.drvPath")
  fi
  source_expr=$(source_expression "$approach")
  pinned_source=$(cd "$example" && nix eval --impure --raw --expr "builtins.toString ($source_expr)")
  [[ $actual_source == "$pinned_source" ]] || { printf 'Package does not use the pinned source: %s\n' "$approach" >&2; exit 1; }
  [[ -d $actual_source && $(nix hash path "$actual_source") == "$expected_hash" ]] || {
    printf 'Unpacked source differs: %s\n' "$approach" >&2; exit 1;
  }

  greeting=$(LC_ALL=C "$example/result/bin/hello")
  version=$(LC_ALL=C "$example/result/bin/hello" --version)
  [[ $greeting == 'Hello, world!' && ${version%%$'\n'*} == 'hello (GNU Hello) 2.12.3' ]] || {
    printf 'Unexpected program output: %s\n' "$approach" >&2; exit 1;
  }
  [[ $(fingerprint "$example") == "$before" ]] || { printf 'Build changed files: %s\n' "$approach" >&2; exit 1; }
  printf '%s: inputs, source, greeting, version, and unchanged files verified\n  %s\n' "$approach" "$drv"
done
