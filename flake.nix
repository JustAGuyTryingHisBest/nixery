{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, zig, ... }:
    let
      inherit (nixpkgs) lib;

      forAllSystems = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (
        system:
        import ./nur {
          pkgs = pkgsFor system;
          zigPackages = zig.packages.${system};
        }
      );

      devShells = forAllSystems (system: {
        default = (pkgsFor system).mkShell {
          packages = [ (pkgsFor system).nixfmt ];
        };
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
