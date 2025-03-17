{
  description = "flake for desktop";

  inputs = {
    nixpkgs.url = "path:/home/zupo/nixpkgs";
  };

  outputs = { self, nixpkgs }: {
      nixosConfigurations = 
        let 
          # skip doing "nix flake update" on every change in /home/zupo/nixpkgs
          pkgs = import /home/zupo/nixpkgs {system="aarch64-linux";};

        in 
        { 
          desktop = pkgs.nixos ./configuration.nix;
      };
  };
}
