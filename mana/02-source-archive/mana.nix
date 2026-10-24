{
  name = "hello-source-archive";
  entrypoint = ./entrypoint.nix;
  dependencies = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83";
      entrypoint = null;
    };
    hello = {
      url = "https://ftp.gnu.org/gnu/hello/hello-2.12.3.tar.gz";
      # Inject the unpacked source instead of importing a Nix entrypoint.
      entrypoint = null;
    };
  };
}
