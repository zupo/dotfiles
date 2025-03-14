{
  description = "flake for desktop";

  inputs = {
    nixpkgs.url = "path:/home/zupo/nixpkgs";
  };

  outputs = { self, nixpkgs }: {
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./configuration.nix
          ];
        };
      };
  };
}
