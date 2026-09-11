{ nixpkgs }:
let
  lib = nixpkgs.lib;
in
lib.makeExtensible (
  self:
  let
    callLibs =
      file:
      import file {
        inherit nixpkgs lib;
        home-network-lib = self;
      };
  in
  {
    remote-builders = callLibs ./remote-builders.nix;
  }
)
