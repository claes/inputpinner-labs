{
  description = "01: GNU Hello from a locked nixpkgs input";

  # The branch describes future updates; flake.lock records the exact tree.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { nixpkgs, ... }:
    let
      # Keep the platform selection visible without a helper dependency.
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in
    {
      packages = builtins.listToAttrs (map (system:
        let
          # Explicit settings keep the package set comparable across pinners.
          pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
        in
        { name = system; value.default = pkgs.hello; }
      ) systems);
    };
}
