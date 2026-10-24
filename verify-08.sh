#!/usr/bin/env bash
# Inspect real consumers and build both packages without changing shipped pins.
set -eEuo pipefail
trap 'printf "Example 08 failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR
cd -- "$(dirname -- "$0")"
root=$PWD
approaches=(flake niv npins lon nixtamal tack mana manual)
examples=()
for approach in "${approaches[@]}"; do
  if [[ $approach == flake || $approach == tack ]]; then
    examples+=("$approach/08-transitive-inputs")
  else
    for library in flake-compat flake-inputs; do
      examples+=("$approach/08-transitive-inputs-$library")
    done
  fi
done
[[ ${#examples[@]} == 14 ]]
if [[ ${1:-} == --syntax-only && $# == 1 ]]; then
  for relative in "${examples[@]}"; do
    while IFS= read -r -d '' expression; do
      nix-instantiate --parse "$expression" > /dev/null
    done < <(find "$relative" -type f -name '*.nix' -print0)
    bash -n "$relative/init.sh"
    bash -n "$relative/update.sh"
  done
  bash -n "$0"
  ./verify-unflake.sh 08 --syntax-only
  printf '%s\n' 'Example 08 Nix and Bash syntax checks passed.'
  exit 0
fi
[[ $# == 0 || ( $# == 1 && $1 == --updates ) ]] || {
  printf '%s\n' 'Usage: ./verify-08.sh [--syntax-only | --updates]' >&2; exit 2;
}
# Native and flake-inputs cases run without IFD; only staged flake-compat needs it.
base_nix_config=${NIX_CONFIG:-}
export NIX_CONFIG="${NIX_CONFIG:-}
allow-import-from-derivation = false"
system=$(nix eval --impure --raw --expr builtins.currentSystem)
[[ $system == x86_64-linux ]] || { printf 'This check targets x86_64-linux; got %s.\n' "$system" >&2; exit 2; }
unset NIV_OVERRIDE_nixpkgs NIV_OVERRIDE_patchelf NIV_OVERRIDE_flake_inputs
unset NPINS_OVERRIDE_nixpkgs NPINS_OVERRIDE_patchelf NPINS_OVERRIDE_flake_inputs
unset LON_OVERRIDE_nixpkgs LON_OVERRIDE_patchelf LON_OVERRIDE_flake_inputs
if [[ ${1:-} == --updates ]]; then
  for command in niv npins lon nixtamal tack; do command -v "$command" > /dev/null; done
fi
scratch=$(mktemp -d "${TMPDIR:-/tmp}/inputpinner-08.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
lock_entry() {
  case "$1" in
    flake) jq -cS --arg n "$3" '.nodes[$n]' "$2/flake.lock" ;;
    niv) jq -cS --arg n "$3" '.[$n]' "$2/nix/sources.json" ;;
    npins) jq -cS --arg n "$3" '.pins[$n]' "$2/npins/sources.json" ;;
    lon) jq -cS --arg n "$3" '.sources[$n]' "$2/lon.lock" ;;
    nixtamal) jq -cS --arg n "$3" '.i[$n]' "$2/nix/tamal/lock.json" ;;
    tack) jq -cS --arg n "$3" '.[$n]' "$2/.tack/pins.lock.json" ;;
    mana) jq -cS --arg n "/$3" '.sources[$n]' "$2/lock.json" ;;
    manual) jq -cS --arg n "$3" '.[$n]' "$2/pins.json" ;;
  esac
}
revision() { lock_entry "$@" | jq -r '.locked.rev // .rev // .revision // .fv'; }
# Store paths are immutable; hash each distinct tree only once per verification.
declare -A source_hashes
check_hash() {
  local path=$1 expected=$2
  [[ $path == /nix/store/* ]]
  if [[ ! -v source_hashes[$path] ]]; then source_hashes[$path]=$(nix hash path "$path"); fi
  [[ ${source_hashes[$path]} == "$expected" ]]
}
fingerprint() { find "$1" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum; }
# Capture the original consumer's let bindings, rather than rebuild its graph in tests.
graph_info() {
  local approach=$1 example=$2 expression parent upstream adapter='null' staged='null' upstream_path capture bindings consumer='import ./. {}'
  case "$approach" in
    flake)
      consumer="(builtins.getFlake (toString ./.)).packages.\"$system\""
      parent='(builtins.getFlake (toString ./.)).inputs.nixpkgs'
      upstream='(builtins.getFlake (toString ./.)).inputs.patchelf'
      expression="let parent = $parent; pkgs = import parent { system = \"$system\"; config = {}; overlays = []; }; upstream = $upstream; in" ;;
    tack)
      expression="let sources = import ./.tack; parent = sources.nixpkgs; upstream = sources.patchelf; pkgs = import parent { system = \"$system\"; config = {}; overlays = []; }; in" ;;
    *)
      if [[ $approach == mana ]]; then
        sed '/^in$/,$d' "$example/entrypoint.nix" > "$example/capture.nix"
        capture='(import ./nix/importer.nix { manifest = (import ./mana.nix) // { entrypoint = ./capture.nix; }; }) {}'
      else
        sed '/^in$/,$d' "$example/default.nix" > "$example/capture.nix"
        capture='import ./capture.nix {}'
      fi
      bindings='sources pkgs upstream'
      if [[ $library == flake-compat ]]; then bindings+=' sharedSource'; staged='toString c.sharedSource'; fi
      printf 'in { inherit %s; }\n' "$bindings" >> "$example/capture.nix"
      expression="let c = ($capture); inherit (c) pkgs upstream; parent = c.sources.nixpkgs; in"
      adapter="toString c.sources.\"$library\"" ;;
  esac
  upstream_path='toString upstream'
  if [[ $library != native ]]; then upstream_path='toString c.sources.patchelf'; fi
  (cd "$example" && nix eval --impure --json --expr "$expression {
    parentPath = toString parent;
    adapterPath = $adapter;
    upstreamPath = $upstream_path;
    stagedPath = $staged;
    paths = map toString [ upstream.inputs.nixpkgs
      upstream.inputs.flake-parts.inputs.nixpkgs-lib
      upstream.inputs.git-hooks-nix.inputs.nixpkgs
      upstream.inputs.git-hooks-nix.inputs.nixpkgs-stable ];
    helloDrv = pkgs.hello.drvPath;
    packageDrv = upstream.packages.\"$system\".default.drvPath;
    packageOut = upstream.packages.\"$system\".default.outPath;
    stdenvDrv = pkgs.stdenv.drvPath;
    dynamicLinker = pkgs.stdenv.cc.bintools.dynamicLinker;
    consumer = let p = $consumer; in {
      helloDrv = p.hello.drvPath;
      helloOut = p.hello.outPath;
      packageDrv = p.patchelf.drvPath;
      packageOut = p.patchelf.outPath;
    };
  }")
  if [[ -e $example/capture.nix ]]; then rm -- "$example/capture.nix"; fi
}
check_pair() {
  local approach=$1 example=$2 expected_hash=$3 info before parent_path upstream_path edge staged_path pin current_hello current_patchelf
  before=$(fingerprint "$example")
  info=$(graph_info "$approach" "$example")
  parent_path=$(jq -r .parentPath <<< "$info")
  upstream_path=$(jq -r .upstreamPath <<< "$info")
  # The staged adapter can fetch the same tree with a different native basename.
  # Every effective edge must have the parent's exact content hash.
  check_hash "$parent_path" "$expected_hash"
  check_hash "$upstream_path" "$patchelf_hash"
  while IFS= read -r edge; do check_hash "$edge" "$expected_hash"; done < <(jq -r '.paths[]' <<< "$info")
  if [[ $library != flake-compat ]]; then
    jq -e --arg parent "$parent_path" 'all(.paths[]; . == $parent)' <<< "$info" > /dev/null
  else
    staged_path=$(jq -r .stagedPath <<< "$info")
    diff -r --exclude=flake.lock "$upstream_path" "$staged_path"
    jq -e --arg rev "$(revision "$approach" "$example" nixpkgs)" --arg hash "$expected_hash" \
      '.nodes[.nodes[.root].inputs.nixpkgs].locked | .rev == $rev and .narHash == $hash' "$staged_path/flake.lock" > /dev/null
    jq -S 'del(.nodes[.nodes[.root].inputs.nixpkgs].locked)' "$upstream_path/flake.lock" > "$scratch/original.json"
    jq -S 'del(.nodes[.nodes[.root].inputs.nixpkgs].locked)' "$staged_path/flake.lock" > "$scratch/shared.json"
    cmp "$scratch/original.json" "$scratch/shared.json"
  fi
  if [[ $approach != flake && $approach != tack ]]; then
    check_hash "$(jq -r .adapterPath <<< "$info")" "$adapter_hash"
  fi
  [[ $(sha256sum "$upstream_path/flake.lock" | cut -d ' ' -f1) == "$upstream_lock_hash" ]]
  for pin in hello patchelf; do
    if [[ $approach == flake ]]; then
      (cd "$example" && nix build "path:.#$pin" --out-link "result-$pin")
    else
      (cd "$example" && nix-build -A "$pin" -o "result-$pin")
    fi
  done
  [[ $("$example/result-hello/bin/hello") == 'Hello, world!' &&
     $("$example/result-patchelf/bin/patchelf" --version) == 'patchelf 0.19.2' ]]
  # A substituted output can name an older deriver; inspect the current consumer.
  current_hello=$(jq -r .consumer.helloDrv <<< "$info")
  current_patchelf=$(jq -r .consumer.packageDrv <<< "$info")
  [[ $(readlink -f "$example/result-hello") == "$(jq -r .consumer.helloOut <<< "$info")" &&
     $(readlink -f "$example/result-patchelf") == "$(jq -r .consumer.packageOut <<< "$info")" ]]
  [[ $current_hello == "$(jq -r .helloDrv <<< "$info")" &&
     $current_patchelf == "$(jq -r .packageDrv <<< "$info")" ]]
  # Both actual packages must use the standard environment from this parent.
  # Query dependencies: structured-attribute derivations need no stdenv env binding.
  nix-store --query --references "$current_hello" | grep -Fx "$(jq -r .stdenvDrv <<< "$info")" > /dev/null
  nix-store --query --references "$current_patchelf" | grep -Fx "$(jq -r .stdenvDrv <<< "$info")" > /dev/null
  [[ $("$example/result-patchelf/bin/patchelf" --print-interpreter "$example/result-hello/bin/hello") == "$(jq -r .dynamicLinker <<< "$info")" ]]
  # Compare against the independent native-flake reference, not just version text.
  if [[ $expected_hash == "$parent_hash" ]]; then
    [[ $current_hello == "$initial_hello_drv" && $current_patchelf == "$initial_patchelf_drv" ]]
  else
    [[ $current_hello == "$alternate_hello_drv" && $current_patchelf == "$alternate_patchelf_drv" &&
       $current_hello != "$initial_hello_drv" && $current_patchelf != "$initial_patchelf_drv" ]]
  fi
  [[ $(fingerprint "$example") == "$before" ]]
  printf '%s: both packages built with the same parent; four follows paths, source hashes and unchanged files verified\n' "$relative"
}
parent=$(cat manual/08-transitive-inputs-flake-inputs/revision)
alternate=$(cat manual/08-transitive-inputs-flake-inputs/alternate-revision)
patchelf=$(cat manual/08-transitive-inputs-flake-inputs/patchelf-revision)

parent_hash='sha256-v72qr4LsSz61tQki/41nHKZKPY6NSeZavtGlAInOCng='
alternate_hash='sha256-ddcX4lQL0X05AYkrkV2LMFgGdRvgap7Ho8kgon3iWZk='
patchelf_hash='sha256-+c7LIYKu0pYnG7h1dsEIDs6l4+91Vh/oDrSDARdBK3o='

# Existing 08's native flake is an independent reference requiring no IFD.
reference=$(cd flake/08-transitive-inputs && nix eval --impure --json --expr '
  let f = builtins.getFlake (toString ./.); in {
    hello = f.inputs.nixpkgs.legacyPackages.x86_64-linux.hello.drvPath;
    patchelf = f.inputs.patchelf.packages.x86_64-linux.default.drvPath;
    upstreamPath = toString f.inputs.patchelf;
  }')
initial_hello_drv=$(jq -r .hello <<< "$reference")
initial_patchelf_drv=$(jq -r .patchelf <<< "$reference")
upstream_lock_hash=$(sha256sum "$(jq -r .upstreamPath <<< "$reference")/flake.lock" | cut -d ' ' -f1)
if [[ ${1:-} == --updates ]]; then
  alternate_hello_drv=$(nix eval --raw "github:NixOS/nixpkgs/$alternate#legacyPackages.$system.hello.drvPath")
  alternate_patchelf_drv=$(nix eval --raw "github:NixOS/patchelf/$patchelf#packages.$system.default.drvPath")
fi
for relative in "${examples[@]}"; do
  approach=${relative%%/*}
  library=native
  if [[ $approach != flake && $approach != tack ]]; then library=flake-${relative##*-flake-}; fi
  ifd=false
  if [[ $library == flake-compat ]]; then ifd=true; fi
  export NIX_CONFIG="$base_nix_config
allow-import-from-derivation = $ifd"
  example="$scratch/lab with spaces/$relative"
  mkdir -p "$example"
  tar -C "$root/$relative" --exclude='./result*' --exclude='*.tmp' \
    --exclude=./next_lock.json -cf - . | tar -C "$example" -xf -
  [[ $(cat "$example/revision") == "$parent" &&
     $(cat "$example/alternate-revision") == "$alternate" &&
     $(cat "$example/patchelf-revision") == "$patchelf" &&
     $(revision "$approach" "$example" nixpkgs) == "$parent" &&
     $(revision "$approach" "$example" patchelf) == "$patchelf" ]]
  if [[ $approach != flake && $approach != tack ]]; then
    adapter=$(cat "$root/manual/08-transitive-inputs-$library/$library-revision")
    adapter_hash=$(nix hash convert --hash-algo sha256 --to sri "$(jq -r --arg n "$library" '.[$n].sha256' "$root/manual/08-transitive-inputs-$library/pins.json")")
    [[ $(cat "$example/$library-revision") == "$adapter" &&
       $(revision "$approach" "$example" "$library") == "$adapter" ]]
  fi
  check_pair "$approach" "$example" "$parent_hash"
  if [[ ${1:-} != --updates ]]; then continue; fi
  upstream_before=$(lock_entry "$approach" "$example" patchelf)
  if [[ $approach != flake && $approach != tack ]]; then adapter_before=$(lock_entry "$approach" "$example" "$library"); fi
  if [[ $approach == mana ]]; then
    # Mana's pinned maintenance CLI fails to quote a cwd containing spaces.
    mv "$example" "$scratch/mana-maintenance"
    (cd "$scratch/mana-maintenance" && ./update.sh)
    mv "$scratch/mana-maintenance" "$example"
  else
    (cd "$example" && ./update.sh)
  fi
  [[ $(revision "$approach" "$example" nixpkgs) == "$alternate" &&
     $(cat "$example/revision") == "$parent" &&
     $(lock_entry "$approach" "$example" patchelf) == "$upstream_before" ]]
  if [[ $approach != flake && $approach != tack ]]; then
    [[ $(lock_entry "$approach" "$example" "$library") == "$adapter_before" ]]
  fi
  check_pair "$approach" "$example" "$alternate_hash"
  printf '%s: changing only the parent pin changed both package derivations\n' "$relative"
done
printf '%s\n' 'Example 08 passed: 14 native/library implementations; IFD enabled only for staged flake-compat.'

./verify-unflake.sh 08 "$@"
