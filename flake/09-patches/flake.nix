{
  description = "09: Patch a pinned source and review a breaking update";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    systems = {
      # main can move; flake.lock fixes the source used by evaluation.
      url = "github:nix-systems/default/main";
      flake = false;
    };
  };

  outputs = { nixpkgs, systems, ... }:
    {
      packages = builtins.listToAttrs (map (system:
        let
          pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
        in
        {
          name = system;
          value.default = pkgs.stdenvNoCC.mkDerivation {
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
      ) [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]);
    };
}
