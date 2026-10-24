{
  name = "systems-from-git-branch";
  entrypoint = ./entrypoint.nix;
  dependencies = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83";
      entrypoint = null;
    };
    systems = {
      # The manifest tracks main; lock.json supplies its selected commit.
      url = "github:nix-systems/default/main";
      entrypoint = null;
    };
  };
}
