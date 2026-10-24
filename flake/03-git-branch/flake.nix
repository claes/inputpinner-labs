{
  description = "03: Consume a Git branch through its locked source commit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    systems = {
      # main can move; flake.lock fixes the source used by evaluation.
      url = "github:nix-systems/default/main";
      flake = false;
    };
  };

  outputs = { nixpkgs, systems, ... }:
    let
      # Import the list from the locked source, not from a moving URL.
      supportedSystems = import systems;
    in
    {
      packages = builtins.listToAttrs (map (system:
        let
          pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
        in
        {
          name = system;
          value.default = pkgs.writeText "systems.txt"
            (builtins.concatStringsSep "\n" supportedSystems + "\n");
        }
      ) [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]);
    };
}
