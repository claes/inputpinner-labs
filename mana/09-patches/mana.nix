{
  name = "patched-systems";
  entrypoint = ./entrypoint.nix;
  dependencies = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83";
      entrypoint = null;
    };
    systems = {
      # Keep an immutable starting point for the patch exercise.
      url = "github:nix-systems/default/da67096a3b9bf56a91d16901293e51ba5b49a27e";
      entrypoint = null;
    };
  };
}
