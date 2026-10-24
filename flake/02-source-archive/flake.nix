{
  description = "02: GNU Hello from a separately pinned source archive";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    hello = {
      url = "https://ftp.gnu.org/gnu/hello/hello-2.12.3.tar.gz";
      # This archive is source code, so do not look for a flake.nix inside it.
      flake = false;
    };
  };

  outputs = { nixpkgs, hello, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in
    {
      packages = builtins.listToAttrs (map (system:
        let
          pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
        in
        {
          name = system;
          # Reuse the existing build recipe, replacing only its source.
          value.default = pkgs.hello.overrideAttrs (_: { src = hello; });
        }
      ) systems);
    };
}
