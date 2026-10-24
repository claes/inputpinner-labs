# Keep raw-source selection separate from patch application during the build.
{ nixpkgs, systems }:
{ system ? builtins.currentSystem }:
let
  pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
in
{
  systems = pkgs.stdenvNoCC.mkDerivation {
    name = "systems.nix";
    src = systems;
    # Patch the build's unpacked copy, preserving the immutable pinned source.
    patches = [ ./local.patch ];
    # Refuse fuzzy matches, reversed patches, and interactive questions.
    patchFlags = [ "-p1" "--fuzz=0" "--forward" "--batch" ];
    dontConfigure = true;
    dontBuild = true;
    # The dependency is Nix data; install it without evaluating a build output.
    installPhase = ''
      runHook preInstall
      cp default.nix "$out"
      runHook postInstall
    '';
  };
}
