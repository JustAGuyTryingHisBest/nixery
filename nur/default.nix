{
  pkgs ? import <nixpkgs> { },
}:
{
  cinder = pkgs.callPackage ./pkgs/cinder/package.nix { };
  hello-nur = pkgs.callPackage ./pkgs/hello-nur/package.nix { };
}
