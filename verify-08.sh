#!/usr/bin/env bash
# Compare effective input graphs in fresh copies; leave shipped pins untouched.
set -euo pipefail
cd -- "$(dirname -- "$0")"
root=$PWD
approaches=(flake niv npins lon nixtamal tack mana manual)
if [[ ${1:-} == --syntax-only && $# == 1 ]]; then
  for approach in "${approaches[@]}"; do
    while IFS= read -r -d '' expression; do
      nix-instantiate --parse "$expression" > /dev/null
    done < <(find "$approach/08-transitive-inputs" -type f -name '*.nix' -print0)
    bash -n "$approach/08-transitive-inputs/init.sh"
  done
  bash -n "$0"
  printf '%s\n' 'Example 08 Nix and Bash syntax checks passed.'
  exit 0
fi
[[ $# == 0 ]] || { printf '%s\n' 'Usage: ./verify-08.sh [--syntax-only]' >&2; exit 2; }
system=$(nix eval --impure --raw --expr builtins.currentSystem)
[[ $system == x86_64-linux ]] || { printf 'This check targets x86_64-linux; got %s.\n' "$system" >&2; exit 2; }
unset NIV_OVERRIDE_nixpkgs NIV_OVERRIDE_patchelf NIV_OVERRIDE_flake_compat
unset NPINS_OVERRIDE_nixpkgs NPINS_OVERRIDE_patchelf NPINS_OVERRIDE_flake_compat
unset LON_OVERRIDE_nixpkgs LON_OVERRIDE_patchelf
scratch_base=$(mktemp -d "${TMPDIR:-/tmp}/inputpinner-08.XXXXXXXX")
trap 'rm -rf -- "$scratch_base"' EXIT
scratch="$scratch_base/lab with spaces"
mkdir -p "$scratch"
locked_revision() {
  case "$1" in
    flake) jq -r --arg n "$3" '.nodes[$n].locked.rev' "$2/flake.lock" ;;
    niv) jq -r --arg n "$3" '.[$n].rev' "$2/nix/sources.json" ;;
    npins) jq -r --arg n "$3" '.pins[$n].revision' "$2/npins/sources.json" ;;
    lon) jq -r --arg n "$3" '.sources[$n].revision' "$2/lon.lock" ;;
    nixtamal) jq -r --arg n "$3" '.i[$n].fv' "$2/nix/tamal/lock.json" ;;
    tack) jq -r --arg n "$3" '.[$n].rev' "$2/.tack/pins.lock.json" ;;
    mana) jq -r --arg n "/$3" '.sources[$n].locked.rev' "$2/lock.json" ;;
    manual) jq -r --arg n "$3" '.[$n].revision' "$2/pins.json" ;;
  esac
}
source_expression() {
  case "$1" in
    flake) printf 'let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in builtins.fetchTree lock.nodes."%s".locked' "$2" ;;
    niv) printf '(import ./nix/sources.nix {})."%s"' "$2" ;;
    npins) printf '(import ./npins)."%s"' "$2" ;;
    lon) printf '(import ./lon.nix)."%s"' "$2" ;;
    nixtamal) printf '(import ./nix/tamal {})."%s"' "$2" ;;
    tack) printf '(import ./.tack)."%s"' "$2" ;;
    mana) printf 'let lock = builtins.fromJSON (builtins.readFile ./lock.json); pin = lock.sources."/%s"; in builtins.fetchTree (builtins.removeAttrs pin.args [ "ref" ] // builtins.removeAttrs pin.locked [ "lastModified" "lastModifiedDate" "shortRev" ])' "$2" ;;
    manual) printf 'let pins = builtins.fromJSON (builtins.readFile ./pins.json); in builtins.fetchTarball { inherit (pins."%s") url sha256; }' "$2" ;;
  esac
}
fingerprint() {
  find "$1" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum
}
revision=$(cat manual/08-transitive-inputs/revision)
patchelf_revision=$(cat manual/08-transitive-inputs/patchelf-revision)
compat_revision=$(cat manual/08-transitive-inputs/flake-compat-revision)
upstream_ref="github:NixOS/patchelf/$patchelf_revision"
upstream_drv=$(nix eval --raw "$upstream_ref#packages.$system.default.drvPath")
expected_nixpkgs_hash=$(nix hash convert --hash-algo sha256 --to sri "$(jq -r .nixpkgs.sha256 manual/08-transitive-inputs/pins.json)")
expected_patchelf_hash=$(nix hash convert --hash-algo sha256 --to sri "$(jq -r .patchelf.sha256 manual/08-transitive-inputs/pins.json)")
expected_compat_hash=$(nix hash convert --hash-algo sha256 --to sri "$(jq -r '."flake-compat".sha256' manual/08-transitive-inputs/pins.json)")
wrapper_drv=''
shared_package_drv=''
upstream_lock_hash=''

for approach in "${approaches[@]}"; do
  example="$scratch/$approach/08-transitive-inputs"
  mkdir -p "$example"
  tar -C "$root/$approach/08-transitive-inputs" \
    --exclude='./result*' --exclude='*.tmp' --exclude=./next_lock.json \
    -cf - . | tar -C "$example" -xf -
  before=$(fingerprint "$example")
  [[ $(cat "$example/revision") == "$revision" &&
     $(cat "$example/patchelf-revision") == "$patchelf_revision" &&
     $(locked_revision "$approach" "$example" nixpkgs) == "$revision" &&
     $(locked_revision "$approach" "$example" patchelf) == "$patchelf_revision" ]]
  for pin in nixpkgs patchelf; do
    expression=$(source_expression "$approach" "$pin")
    source=$(cd "$example" && nix eval --impure --raw --expr "builtins.toString ($expression)")
    if [[ $pin == nixpkgs ]]; then
      parent_source=$source
      [[ $(nix hash path "$source") == "$expected_nixpkgs_hash" ]]
    else
      patchelf_source=$source
      [[ $(nix hash path "$source") == "$expected_patchelf_hash" ]]
    fi
  done
  original_lock_hash=$(sha256sum "$patchelf_source/flake.lock" | cut -d ' ' -f1)
  if [[ -z $upstream_lock_hash ]]; then upstream_lock_hash=$original_lock_hash; fi
  [[ $original_lock_hash == "$upstream_lock_hash" ]]
  jq -e '.nodes.nixpkgs.locked.rev == "c69a9bffbecde46b4b939465422ddc59493d3e4d"' "$patchelf_source/flake.lock" > /dev/null

  if [[ $approach == flake ]]; then
    graph_expression='(builtins.getFlake (toString ./.)).inputs.patchelf'
    jq -e '.nodes.patchelf.inputs.nixpkgs == ["nixpkgs"]' "$example/flake.lock" > /dev/null
  elif [[ $approach == tack ]]; then
    graph_expression='(import ./.tack).patchelf'
  else
    [[ $(cat "$example/flake-compat-revision") == "$compat_revision" &&
       $(locked_revision "$approach" "$example" flake-compat) == "$compat_revision" ]]
    expression=$(source_expression "$approach" flake-compat)
    compat_source=$(cd "$example" && nix eval --impure --raw --expr "builtins.toString ($expression)")
    [[ $(nix hash path "$compat_source") == "$expected_compat_hash" ]]
    # Inspect exactly the staged tree selected by the consumer, including IFD.
    if [[ $approach == mana ]]; then
      # Capture the value from the unchanged entrypoint's let bindings.
      capture_expression='(import ./nix/importer.nix) { manifest = (import ./mana.nix) // { entrypoint = ./. + "/capture-shared.nix"; }; }'
      # The dependency arguments and source selection remain the real example's code.
      sed '/^in$/,$d' "$example/entrypoint.nix" > "$example/capture-shared.nix"
      printf '%s\n' 'in { inherit sharedSource upstreamFlake; }' >> "$example/capture-shared.nix"
      capture_expression="($capture_expression) {}"
    else
      sed '/^in$/,$d' "$example/default.nix" > "$example/capture-shared.nix"
      printf '%s\n' 'in { inherit sharedSource upstreamFlake; }' >> "$example/capture-shared.nix"
      capture_expression='import ./capture-shared.nix {}'
    fi
    staged_source=$(cd "$example" && nix-build --no-out-link --expr "($capture_expression).sharedSource")
    graph_expression="($capture_expression).upstreamFlake"
    # The original tree is immutable; only the copied lock is changed.
    diff -r --exclude=flake.lock "$patchelf_source" "$staged_source"
    jq -e --arg revision "$revision" --arg hash "$expected_nixpkgs_hash" \
      '.nodes[.nodes[.root].inputs.nixpkgs].locked | .rev == $revision and .narHash == $hash' \
      "$staged_source/flake.lock" > /dev/null
    jq -S 'del(.nodes.nixpkgs.locked)' "$patchelf_source/flake.lock" > "$scratch/original.json"
    jq -S 'del(.nodes.nixpkgs.locked)' "$staged_source/flake.lock" > "$scratch/shared.json"
    cmp "$scratch/original.json" "$scratch/shared.json"
  fi

  # These paths exercise both the direct dependency and existing transitive aliases.
  graph_info=$(cd "$example" && nix eval --impure --json --expr "
    let f = ($graph_expression); in {
      revisions = [ f.inputs.nixpkgs.rev
        f.inputs.flake-parts.inputs.nixpkgs-lib.rev
        f.inputs.git-hooks-nix.inputs.nixpkgs.rev
        f.inputs.git-hooks-nix.inputs.nixpkgs-stable.rev ];
      hashes = [ f.inputs.nixpkgs.narHash
        f.inputs.flake-parts.inputs.nixpkgs-lib.narHash
        f.inputs.git-hooks-nix.inputs.nixpkgs.narHash
        f.inputs.git-hooks-nix.inputs.nixpkgs-stable.narHash ];
      packageDrv = f.packages.\"$system\".default.drvPath;
      packageOut = f.packages.\"$system\".default.outPath;
    }")
  jq -e --arg rev "$revision" --arg hash "$expected_nixpkgs_hash" \
    'all(.revisions[]; . == $rev) and all(.hashes[]; . == $hash)' <<< "$graph_info" > /dev/null
  current_package=$(jq -r .packageDrv <<< "$graph_info")
  [[ $current_package != "$upstream_drv" ]]
  if [[ -z $shared_package_drv ]]; then shared_package_drv=$current_package; fi
  [[ $current_package == "$shared_package_drv" ]]
  if [[ $approach != flake && $approach != tack ]]; then
    # Remove the temporary inspection entrypoint before checking build immutability.
    rm -- "$example/capture-shared.nix"
  fi
  parent_info=$(PARENT_SOURCE="$parent_source" nix eval --impure --json --expr "
    let p = import (/. + builtins.getEnv \"PARENT_SOURCE\") { system = \"$system\"; config = {}; overlays = []; };
    in { stdenv = p.stdenv.outPath; dynamicLinker = p.stdenv.cc.bintools.dynamicLinker; }")
  [[ $(nix-store --query --binding stdenv "$current_package") == "$(jq -r .stdenv <<< "$parent_info")" ]]

  if [[ $approach == flake ]]; then
    (cd "$example" && nix build path:.)
  elif [[ $approach == mana ]]; then
    (cd "$example" && nix-build -A patchelf-demo)
  else
    (cd "$example" && nix-build)
  fi
  package_output=$(jq -r .packageOut <<< "$graph_info")
  [[ $("$example/result/bin/patchelf-demo" --version) == 'patchelf 0.19.2' ]]
  [[ $("$example/result/bin/patchelf-demo" --print-interpreter "$package_output/bin/patchelf") == "$(jq -r .dynamicLinker <<< "$parent_info")" ]]
  nix-store --query --references "$example/result" | grep -Fx "$package_output" > /dev/null
  current_wrapper=$(nix-store --query --deriver "$example/result")
  if [[ -z $wrapper_drv ]]; then wrapper_drv=$current_wrapper; fi
  [[ $current_wrapper == "$wrapper_drv" ]]
  [[ $(fingerprint "$example") == "$before" ]]
  printf '%s: parent sharing at every inspected edge, retained source pins, matching package and wrapper, and unchanged files verified\n' "$approach"
done

# A changed active pin must propagate even while initialization seeds stay old.
updated="$scratch/updated-parent"
mkdir -p "$updated"
tar -C "$root/manual/08-transitive-inputs" --exclude='./result*' -cf - . | tar -C "$updated" -xf -
new_revision=$(jq -r '.nodes.nixpkgs.locked.rev' "$patchelf_source/flake.lock")
new_hash=$(jq -r '.nodes.nixpkgs.locked.narHash' "$patchelf_source/flake.lock")
jq --arg rev "$new_revision" --arg hash "$new_hash" \
  '.nixpkgs = {revision: $rev, url: ("https://github.com/NixOS/nixpkgs/archive/" + $rev + ".tar.gz"), sha256: $hash}' \
  "$updated/pins.json" > "$updated/pins.json.tmp"
mv "$updated/pins.json.tmp" "$updated/pins.json"
sed '/^in$/,$d' "$updated/default.nix" > "$updated/capture-shared.nix"
printf '%s\n' 'in { inherit sharedSource upstreamFlake; }' >> "$updated/capture-shared.nix"
changed_info=$(cd "$updated" && nix eval --impure --json --expr "
  let f = (import ./capture-shared.nix {}).upstreamFlake; in {
    revision = f.inputs.nixpkgs.rev;
    packageDrv = f.packages.\"$system\".default.drvPath;
    packageOut = f.packages.\"$system\".default.outPath;
  }")
[[ $(cat "$updated/revision") == "$revision" && $(jq -r .revision <<< "$changed_info") == "$new_revision" ]]
[[ $(jq -r .packageDrv <<< "$changed_info") == "$upstream_drv" ]]
rm -- "$updated/capture-shared.nix"
updated_before=$(fingerprint "$updated")
(cd "$updated" && nix-build)
nix-store --query --references "$updated/result" | grep -Fx "$(jq -r .packageOut <<< "$changed_info")" > /dev/null
[[ $("$updated/result/bin/patchelf-demo" --version) == 'patchelf 0.19.2' ]]
[[ $(fingerprint "$updated") == "$updated_before" ]]
printf '%s\n' 'Changed parent pin propagated through the adapter; initialization seed remained unchanged.'
