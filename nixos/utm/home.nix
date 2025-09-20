{
  pkgs,
  pkgsUnstable,
  commonModules,
  mcp-nixos,
  ...
}:
{
  imports = [
    commonModules.direnv
    commonModules.files
    commonModules.vim
    commonModules.gitconfig
    commonModules.zsh
    (commonModules.tools {
      inherit pkgs pkgsUnstable mcp-nixos;
    })

  ];

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  # UTM VM-specific zsh configuration
  programs.zsh = {
    sessionVariables = {
      EDITOR = "vim";
    };

    shellAliases = {
      nixre = "sudo nixos-rebuild switch --flake /home/zupo/.dotfiles#utm";
      nixgc = "nix-collect-garbage -d";
      nixcfg = "vim /home/zupo/.dotfiles/nixos/utm/configuration.nix";
    };
  };

  # Additional VM-specific packages if needed
  home.packages = with pkgs; [
    # Development tools specific to VM environment
    docker-compose
  ];

  # Git configuration adjustments for VM
  programs.git.extraConfig = {
    safe.directory = "/home/zupo/.dotfiles";
  };
}
