{
  pkgs ? import <nixpkgs> { },
  zigPackages ?
    (builtins.getFlake "github:mitchellh/zig-overlay").packages.${pkgs.stdenv.hostPlatform.system},
}:
let
  zigHook_0_17 = pkgs.callPackage ./pkgs/zig-hook/package.nix { zig = zigPackages."0.17.0"; };
in
{
  bs = pkgs.callPackage ./pkgs/bs/package.nix { zigHook = zigHook_0_17; };
  cinder = pkgs.callPackage ./pkgs/cinder/package.nix { };
  hello-nur = pkgs.callPackage ./pkgs/hello-nur/package.nix { };
}
