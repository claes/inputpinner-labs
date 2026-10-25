#!/usr/bin/env bash
# Companion to verify-06/07/08: inspect the direct with-inputs consumers.
set -eEuo pipefail
trap 'printf "With-inputs verification failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR
cd -- "$(dirname -- "$0")"
root=$PWD
number=${1:?Usage: ./verify-with-inputs.sh 06|07|08 [--syntax-only|--updates]}
shift
case $number in
  06) slug=flake-package ;;
  07) slug=flake-overlay ;;
  08) slug=transitive-inputs ;;
  *) printf '%s\n' 'Expected exercise 06, 07, or 08.' >&2; exit 2 ;;
esac
[[ $# == 0 || ( $# == 1 && $1 == --syntax-only ) ||
   ( $# == 1 && $1 == --updates && $number == 08 ) ]] || exit 2
approaches=(niv npins lon nixtamal mana manual)
if [[ ${1:-} == --syntax-only ]]; then
  for approach in "${approaches[@]}"; do
    example="$approach/$number-$slug-with-inputs"
    while IFS= read -r -d '' file; do
      nix-instantiate --parse "$file" > /dev/null
    done < <(find "$example" -name '*.nix' -type f -print0)
    bash -n "$example/init.sh"
    if [[ $number == 08 ]]; then bash -n "$example/update.sh"; fi
  done
  bash -n "$0"
  printf 'Example %s: six with-inputs variants passed syntax checks.\n' "$number"
  exit 0
fi
export NIX_CONFIG="${NIX_CONFIG:-}
allow-import-from-derivation = false"
ifd_options=(--option allow-import-from-derivation false)
system=$(nix eval --impure --raw --expr builtins.currentSystem)
[[ $system == x86_64-linux ]] || { printf '%s\n' 'These checks target x86_64-linux.' >&2; exit 2; }
# Isolate builds from shell-level source overrides.
while IFS= read -r variable; do
  case $variable in NIV_OVERRIDE_*|NPINS_OVERRIDE_*|LON_OVERRIDE_*) unset "$variable" ;; esac
done < <(compgen -v)
scratch=$(mktemp -d "${TMPDIR:-/tmp}/verify-with-inputs-$number.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
fingerprint() { find "$1" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum; }
# Canonical native records let updates prove that every non-parent pin stayed put.
records() {
  case $1 in
    niv) jq -cS . "$2/nix/sources.json" ;;
    npins) jq -cS .pins "$2/npins/sources.json" ;;
    lon) jq -cS .sources "$2/lon.lock" ;;
    nixtamal) jq -cS .i "$2/nix/tamal/lock.json" ;;
    mana) jq -cS '.sources | with_entries(.key |= ltrimstr("/"))' "$2/lock.json" ;;
    manual) jq -cS . "$2/pins.json" ;;
  esac
}
revision() { records "$1" "$2" | jq -r --arg name "$3" '.[$name] | .rev // .revision // .fv // .locked.rev'; }
# Inspect the public project interface; no source rewriting or private bindings.
graph() {
  local example=$1 override=${2:-false}
  (cd "$example" && nix eval "${ifd_options[@]}" --impure --json --expr "
    let
      project = import ./. (if $override then {
        inputsOverrides.nixpkgs.outPath = builtins.fetchTarball {
          url = \"https://github.com/NixOS/nixpkgs/archive/$old.tar.gz\";
          sha256 = \"$old_hash\";
        };
      } else {});
      inputs = project.inputs;
      upstream = inputs.patchelf;
      pkgs = import inputs.nixpkgs {
        system = \"$system\";
        config = {};
        overlays = if \"$number\" == \"07\" then [ upstream.overlays.default ] else [];
      };
    in {
      parent = toString inputs.nixpkgs;
      upstreamSource = toString inputs.patchelf;
      # Nixtamal consumes the package/overlay only; do not force development inputs.
      paths = map toString ([ upstream.inputs.nixpkgs ] ++
        (if \"$approach\" == \"nixtamal\" then [] else [
          upstream.inputs.flake-parts.inputs.nixpkgs-lib
          upstream.inputs.git-hooks-nix.inputs.nixpkgs
          upstream.inputs.git-hooks-nix.inputs.nixpkgs-stable ]));
      disconnected = if \"$approach\" == \"nixtamal\" then null else
        upstream.inputs.git-hooks-nix.inputs.flake-compat == {}
        && upstream.inputs.git-hooks-nix.inputs.gitignore == {};
      adapterSource = toString inputs.with-inputs;
      outputNames = builtins.attrNames project.outputs;
      selfWorks = project._type == \"flake\"
        && toString inputs.self.outPath == toString ./.
        && builtins.attrNames inputs.self.outputs == builtins.attrNames project.outputs
        && toString inputs.self.inputs.nixpkgs == toString inputs.nixpkgs;
      packageDrv = upstream.packages.\"$system\".default.drvPath;
      packageOut = upstream.packages.\"$system\".default.outPath;
      originalVersion = pkgs.patchelf.version;
      stdenvDrv = pkgs.stdenv.drvPath;
      dynamicLinker = pkgs.stdenv.cc.bintools.dynamicLinker;
      consumer = if \"$number\" == \"06\" then
        { drv = project.patchelf-demo.drvPath; out = project.patchelf-demo.outPath; }
      else if \"$number\" == \"07\" then
        { drv = project.patchelf-new.drvPath; out = project.patchelf-new.outPath; }
      else { drv = project.patchelf.drvPath; out = project.patchelf.outPath;
             helloDrv = project.hello.drvPath; helloOut = project.hello.outPath; };
    }")
}
declare -A hashes
hash() {
  if [[ ! -v hashes[$1] ]]; then hashes[$1]=$(nix hash path "$1"); fi
  [[ ${hashes[$1]} == "$2" ]]
}
parent_hash='sha256-v72qr4LsSz61tQki/41nHKZKPY6NSeZavtGlAInOCng='
old_hash='sha256-ddcX4lQL0X05AYkrkV2LMFgGdRvgap7Ho8kgon3iWZk='
patchelf_hash='sha256-+c7LIYKu0pYnG7h1dsEIDs6l4+91Vh/oDrSDARdBK3o='
parent=$(cat "manual/$number-$slug-with-inputs/revision")
old=c69a9bffbecde46b4b939465422ddc59493d3e4d
# Native references independently select the intended package and overlay recipe.
if [[ $number != 08 ]]; then
reference=$(cd "$root/flake/$number-$slug" && nix eval --impure --json --expr "
  let f = builtins.getFlake (toString ./.); in {
    drv = f.packages.\"$system\".default.drvPath;
    out = f.packages.\"$system\".default.outPath;
  }")
fi
if [[ $number == 08 ]]; then
  # 08 names both outputs explicitly.
  reference=$(cd "$root/flake/$number-$slug" && nix eval --impure --json --expr "
    let p = (builtins.getFlake (toString ./.)).packages.\"$system\"; in {
      drv = p.patchelf.drvPath; out = p.patchelf.outPath;
      helloDrv = p.hello.drvPath;
    }")
fi
upstream_drv=$(nix eval --raw "github:NixOS/patchelf/$(cat "manual/$number-$slug-with-inputs/patchelf-revision")#packages.$system.default.drvPath")
check() {
  local example=$1 expected_parent_hash=$2 expected_upstream_hash=$3 before info current
  before=$(fingerprint "$example")
  info=$(graph "$example")
  hash "$(jq -r .parent <<< "$info")" "$expected_parent_hash"
  hash "$(jq -r .upstreamSource <<< "$info")" "$patchelf_hash"
  hash "$(jq -r .adapterSource <<< "$info")" 'sha256-y98sqtCGDKnD90PMK5qV3ux94sg/Fc/8Ka9+T8YeieE='
  while IFS= read -r path; do hash "$path" "$expected_upstream_hash"; done < <(jq -r '.paths[]' <<< "$info")
  jq -e .selfWorks <<< "$info" > /dev/null
  if [[ $approach != nixtamal ]]; then
    jq -e .disconnected <<< "$info" > /dev/null
  fi
  case $number in
    06) expected_names='["patchelf-demo"]' ;;
    07) expected_names='["patchelf-new"]' ;;
    08) expected_names='["hello","patchelf"]' ;;
  esac
  [[ $(jq -c .outputNames <<< "$info") == "$expected_names" ]]
  if [[ $number == 08 ]]; then
    jq -e '.parent as $parent | all(.paths[]; . == $parent)' <<< "$info" > /dev/null
    (cd "$example" && nix-build "${ifd_options[@]}" -A hello -o result-hello && nix-build "${ifd_options[@]}" -A patchelf -o result-patchelf)
    [[ $("$example/result-hello/bin/hello") == 'Hello, world!' &&
       $("$example/result-patchelf/bin/patchelf" --version) == 'patchelf 0.19.2' ]]
    [[ $(readlink -f "$example/result-hello") == "$(jq -r .consumer.helloOut <<< "$info")" &&
       $(readlink -f "$example/result-patchelf") == "$(jq -r .consumer.out <<< "$info")" ]]
    for current in "$(jq -r .consumer.drv <<< "$info")" "$(jq -r .consumer.helloDrv <<< "$info")"; do
      nix-store --query --references "$current" | grep -Fx "$(jq -r .stdenvDrv <<< "$info")" > /dev/null
    done
    [[ $(jq -r .consumer.helloDrv <<< "$info") == "$expected_hello" ]]
    [[ $("$example/result-patchelf/bin/patchelf" --print-interpreter "$example/result-hello/bin/hello") == "$(jq -r .dynamicLinker <<< "$info")" ]]
  else
    if [[ $number == 06 ]]; then attribute=patchelf-demo; else attribute=patchelf-new; fi
    (cd "$example" && nix-build "${ifd_options[@]}" -A "$attribute")
    [[ $(readlink -f "$example/result") == "$(jq -r .consumer.out <<< "$info")" ]]
    if [[ $number == 06 ]]; then
      [[ $("$example/result/bin/patchelf-demo" --version) == 'patchelf 0.19.2' ]]
      nix-store --query --references "$example/result" | grep -Fx "$(jq -r .packageOut <<< "$info")" > /dev/null
      [[ $("$example/result/bin/patchelf-demo" --print-interpreter "$(jq -r .packageOut <<< "$info")/bin/patchelf") == "$("$(jq -r .packageOut <<< "$info")/bin/patchelf" --print-interpreter "$(jq -r .packageOut <<< "$info")/bin/patchelf")" ]]
    else
      [[ $("$example/result/bin/patchelf" --version) == 'patchelf 0.19.2' && $(jq -r .originalVersion <<< "$info") == 0.15.2 ]]
      nix-store --query --references "$(jq -r .consumer.drv <<< "$info")" | grep -Fx "$(jq -r .stdenvDrv <<< "$info")" > /dev/null
    fi
    [[ $(jq -r .packageDrv <<< "$info") == "$upstream_drv" ]]
  fi
  [[ $(jq -r .consumer.drv <<< "$info") == "$expected_drv" ]]
  [[ $(fingerprint "$example") == "$before" ]]
  printf '%s: resolved graph, native sources, matching builds and unchanged files verified\n' "$relative"
}
initial_drv=$(jq -r .drv <<< "$reference")
expected_hello=$(jq -r .helloDrv <<< "$reference")
if [[ $number == 08 ]]; then
  alternate_hello=$(nix eval --raw "github:NixOS/nixpkgs/$old#legacyPackages.$system.hello.drvPath")
fi
for approach in "${approaches[@]}"; do
  # Only Nixtamal's native loader reads build-time archive outputs during evaluation.
  ifd_options=(--option allow-import-from-derivation false)
  if [[ $approach == nixtamal ]]; then
    ifd_options=(--option allow-import-from-derivation true)
  fi
  relative="$approach/$number-$slug-with-inputs"
  example="$scratch/lab with spaces/$relative"
  mkdir -p "$example"
  tar -C "$root/$relative" --exclude='./result*' --exclude='*.tmp' -cf - . | tar -C "$example" -xf -
  [[ $(revision "$approach" "$example" nixpkgs) == "$parent" ]]
  [[ $(revision "$approach" "$example" patchelf) == "$(cat "$example/patchelf-revision")" ]]
  expected_count=6
  if [[ $number == 08 ]]; then expected_count=5; fi
  if [[ $approach == nixtamal ]]; then expected_count=$((expected_count - 2)); fi
  [[ $(records "$approach" "$example" | jq length) == "$expected_count" ]]
  for seed in "$example"/*-revision; do
    name=${seed##*/}; name=${name%-revision}
    [[ $name == alternate ]] && continue
    [[ $(revision "$approach" "$example" "$name") == "$(cat "$seed")" ]]
  done
  expected_drv=$initial_drv
  if [[ $number == 08 ]]; then upstream_hash=$parent_hash; else upstream_hash=$old_hash; fi
  check "$example" "$parent_hash" "$upstream_hash"
  if [[ $number == 08 && $approach != nixtamal ]]; then
    # Exercise the public override argument without modifying native records.
    before_override=$(fingerprint "$example")
    override_info=$(graph "$example" true)
    hash "$(jq -r .parent <<< "$override_info")" "$old_hash"
    jq -e '.selfWorks and .disconnected and
      (.parent as $parent | all(.paths[]; . == $parent))' <<< "$override_info" > /dev/null
    [[ $(jq -r .consumer.drv <<< "$override_info") == "$upstream_drv" &&
       $(jq -r .consumer.helloDrv <<< "$override_info") == "$alternate_hello" &&
       $(jq -r .consumer.drv <<< "$override_info") != "$initial_drv" &&
       $(jq -r .consumer.helloDrv <<< "$override_info") != "$expected_hello" &&
       $(fingerprint "$example") == "$before_override" ]]
    printf '%s: caller override changed both packages without changing project files\n' "$relative"
  fi
  if [[ ${1:-} != --updates ]]; then continue; fi
  before_records=$(records "$approach" "$example" | jq -cS 'del(.nixpkgs)')
  consumer_file=default.nix
  if [[ $approach == mana ]]; then consumer_file=entrypoint.nix; fi
  evaluator_before=$(sha256sum "$example/$consumer_file" | cut -d ' ' -f1)
  initial_hello=$expected_hello
  if [[ $approach == mana ]]; then
    mv "$example" "$scratch/mana-maintenance"
    (cd "$scratch/mana-maintenance" && ./update.sh)
    mv "$scratch/mana-maintenance" "$example"
  else
    (cd "$example" && ./update.sh)
  fi
  [[ $(revision "$approach" "$example" nixpkgs) == "$old" &&
     $(records "$approach" "$example" | jq -cS 'del(.nixpkgs)') == "$before_records" &&
     $(sha256sum "$example/$consumer_file" | cut -d ' ' -f1) == "$evaluator_before" &&
     $(cat "$example/revision") == "$parent" ]]
  expected_drv=$upstream_drv
  expected_hello=$alternate_hello
  [[ $expected_drv != "$initial_drv" && $expected_hello != "$initial_hello" ]]
  check "$example" "$old_hash" "$old_hash"
  expected_hello=$initial_hello
  printf '%s: parent-only update changed both packages; consumer stayed unchanged\n' "$relative"
done
printf 'Example %s: all six with-inputs variants passed; IFD enabled only for Nixtamal.\n' "$number"
