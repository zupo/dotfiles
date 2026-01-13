{
  description = "zupo's multi-system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Darwin support
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # MCP NixOS tool
    mcp-nixos.url = "github:utensils/mcp-nixos";

    # Claude Code plugins
    claude-plugins.url = "github:anthropics/claude-plugins-official";
    claude-plugins.flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nix-darwin,
      home-manager,
      mcp-nixos,
      claude-plugins,
    }:
    let
      # Common modules that can be imported by any system
      commonModules = {
        ai = import ./common/ai.nix;
        gitconfig = import ./common/gitconfig.nix;
        tools = import ./common/tools.nix;
        direnv = import ./common/direnv.nix;
        vim = import ./common/vim.nix;
        zsh = import ./common/zsh.nix;
        files = import ./common/files.nix;
      };

      # Helper function to create pkgsUnstable for any system
      mkPkgsUnstable =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

    in
    {
      # macOS configuration
      darwinConfigurations."zbook" = nix-darwin.lib.darwinSystem {
        modules = [
          ./darwin/zbook.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.zupo = import ./darwin/home.nix;
            home-manager.extraSpecialArgs = {
              pkgsUnstable = mkPkgsUnstable "aarch64-darwin";
              inherit commonModules mcp-nixos claude-plugins;
            };
          }
        ];
      };

      # NixOS VM configuration for UTM
      nixosConfigurations."utm" = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux"; # or "x86_64-linux" depending on your VM
        modules = [
          ./nixos/utm/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.zupo = import ./nixos/utm/home.nix;
            home-manager.extraSpecialArgs = {
              pkgsUnstable = mkPkgsUnstable "aarch64-linux";
              inherit commonModules mcp-nixos claude-plugins;
            };
          }
        ];
      };

      # Export common modules for use by other flakes (like your remote server)
      lib = commonModules;
    };
}
