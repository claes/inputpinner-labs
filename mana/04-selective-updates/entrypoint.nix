# entrypoint = null in the manifest requests raw sources.
{ stable, unstable }:
{ system ? builtins.currentSystem }:
{
  # The inputs remain separate package sets, even when Hello versions match.
  stable = (import stable { inherit system; config = {}; overlays = []; }).hello;
  unstable = (import unstable { inherit system; config = {}; overlays = []; }).hello;
}
