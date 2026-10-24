{
  name = "hello";
  description = "01: GNU Hello with an injected nixpkgs source";
  entrypoint = ./entrypoint.nix;

  dependencies.nixpkgs = {
    # Start at the same commit as the other examples.
    url = "github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83";
    # Ask for the source tree; entrypoint.nix imports it explicitly.
    entrypoint = null;
  };
}
