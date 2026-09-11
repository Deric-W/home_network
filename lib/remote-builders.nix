with builtins;
{
  nixpkgs,
  lib,
  ...
}:
rec {
  /**
    Selects the fastest entry from `nix.buildMachines`.
  */
  fastest-builder =
    config: head (sort (a: b: b.speedFactor lessThan a.speedFactor) config.nix.buildMachines);

  /**
    Evaluates to the native nixpkgs associated with the builder returned
    by `fastest-builder`.
  */
  fastest-pkgs = config: nixpkgs.legacyPackages.${(fastest-builder config).system};

  /**
    Evaluates to the nixpkgs to use when compiling software for the
    host platform on the builder returned by `fastest-builder`
  */
  fastest-crossPkgs =
    config:
    let
      fastest-system = (fastest-builder config).system;
      host-platform = lib.systems.elaborate config.nixpkgs.hostPlatform;
      matching-platforms = lib.attrNames (
        lib.filterAttrs (
          name: sys: lib.systems.equals host-platform (lib.systems.elaborate sys)
        ) lib.systems.examples
      );
    in
    if length matching-platforms == 1 then
      (fastest-pkgs config).pkgsCross.${head matching-platforms}
    else
      warn "no unambiguously matching platform found, falling back to importing nixpkgs"
      import nixpkgs.outPath {
        localSystem = fastest-system;
        crossSystem = config.nixpkgs.hostPlatform;
      };
}
