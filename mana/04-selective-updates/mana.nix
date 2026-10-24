{
  name = "selective-updates";
  entrypoint = ./entrypoint.nix;
  dependencies = {
    stable = {
      url = "github:NixOS/nixpkgs/nixos-26.05";
      entrypoint = null;
    };
    unstable = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      entrypoint = null;
    };
  };
}
