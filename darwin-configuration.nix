{ config, pkgs, ... }:

let
  inherit (pkgs) lorri;

in {
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 8;
  nix.buildCores = 8;

  # Allow licensed binaries
  nixpkgs.config.allowUnfree = true; 

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =[
    pkgs.axel
    pkgs.bat
    pkgs.direnv
    pkgs.gitAndTools.diff-so-fancy
    pkgs.lorri
    pkgs.ncdu
    pkgs.ngrok
    pkgs.nmap
    pkgs.prettyping
    pkgs.pwgen
    pkgs.s3cmd
    pkgs.telnet
    pkgs.tldr
    pkgs.unrar
    pkgs.vim
    pkgs.wget
    pkgs.youtube-dl
  ];

  # Automatically start the lorri daemon
  launchd.user.agents = {
    "lorri" = {
      serviceConfig = {
        WorkingDirectory = (builtins.getEnv "HOME");
        EnvironmentVariables = { };
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/var/tmp/lorri.log";
        StandardErrorPath = "/var/tmp/lorri.log";
      };
      script = ''
        source ${config.system.build.setEnvironment}
        exec ${lorri}/bin/lorri daemon
      '';
    };
  };  

}
