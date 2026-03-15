{
  description = "Booklore Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    booklore-src = {
      url = "github:booklore-app/booklore?ref=master";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      booklore-src,
    }@inputs:
    let
      inherit (nixpkgs) lib;
      systems = lib.systems.flakeExposed;
      pkgsFor = lib.genAttrs systems (system: import nixpkgs { inherit system; });
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    in
    {
      nixosModules.booklore = import ./nixos/modules/booklore.nix self;
      packages = forEachSystem (pkgs: rec {
        default = booklore;
        booklore = pkgs.callPackage ./booklore.nix { inherit inputs; };
        update = pkgs.callPackage ./update.nix { inherit inputs; };
      });
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.booklore
          ./nixos/vm-test.nix
        ];
      };
    };
}
