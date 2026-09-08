# Classifies the published package set for CI. Pure evaluation: no side effects
# and no network, so it is safe to evaluate on any system.
#
# `buildPkgs`  - packages CI should build
# `cachePkgs`  - packages CI should additionally push to a binary cache
# `buildOutputs` / `cacheOutputs` - every output of the above, since a package
#                may produce more than one store path.
{
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (pkgs) lib;

  # `lib.isDerivation` also excludes a reserved `lib` / `modules` / `overlays`
  # namespace, should one ever be added to the NUR.
  publishedPackages = lib.filter lib.isDerivation (
    lib.attrValues (import ./default.nix { inherit pkgs; })
  );

  # `meta.license.free or true` deliberately admits a package whose `license` is
  # a list, or absent entirely, matching the nur-packages-template behaviour.
  isBuildable = package: !(package.meta.broken or false) && (package.meta.license.free or true);

  isCacheable = package: isBuildable package && !(package.preferLocalBuild or false);

  outputsOf = package: map (outputName: package.${outputName}) package.outputs;

  buildablePackages = lib.filter isBuildable publishedPackages;
  cacheablePackages = lib.filter isCacheable publishedPackages;
in
{
  buildPkgs = buildablePackages;
  cachePkgs = cacheablePackages;
  buildOutputs = lib.concatMap outputsOf buildablePackages;
  cacheOutputs = lib.concatMap outputsOf cacheablePackages;
}
