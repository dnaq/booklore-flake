{
  description = "grimmory Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    grimmory-src = {
      url = "github:grimmory-tools/grimmory?ref=develop";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      grimmory-src,
    }@inputs:
    let
      inherit (nixpkgs) lib;
      systems = lib.systems.flakeExposed;
      pkgsFor = lib.genAttrs systems (system: import nixpkgs { inherit system; });
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    in
    {
      nixosModules.grimmory = import ./nixos/modules/grimmory.nix self;
      packages = forEachSystem (pkgs: rec {
        default = grimmory;
        grimmory = pkgs.callPackage ./grimmory.nix { inherit inputs; };
        update = pkgs.callPackage ./update.nix { inherit inputs; };
      });
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.grimmory
          ./nixos/vm-test.nix
        ];
      };
    };
}
