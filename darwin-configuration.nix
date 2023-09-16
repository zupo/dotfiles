{ config, pkgs, ... }:
{

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # Automatically manage build users
  nix.configureBuildUsers = true;

  # By default, Nix is installed in multi-user mode, and needs a daemon running
  services.nix-daemon.enable = true;
  nix.settings.trusted-users = [ "root" "zupo" ];

  # Automatically run `nix-store --optimize` to save disk space
  nix.settings.auto-optimise-store = true;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.settings.max-jobs = 8;
  nix.settings.cores = 8;

  # Allow licensed binaries
  nixpkgs.config.allowUnfree = true;

  # Pin nixpkgs
  nix.package = pkgs.nix;
  nix.nixPath = [
    "nixpkgs=${import /Users/zupo/.dotfiles/pins/nixpkgs.nix}"
    "darwin=${import /Users/zupo/.dotfiles/pins/darwin.nix}"
    "nixos-config=/Users/zupo/.nixpkgs/darwin-configuration.nix"
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  # Default prompt includes `prompt walters` that adds an annoying
  # "current path" info to the right of the terminal line, which makes
  # copy/pasting terminal output a pain
  programs.zsh.promptInit = "autoload -U promptinit && promptinit";

  # make sure firewall is up & running
  system.defaults.alf.globalstate = 1;
  system.defaults.alf.stealthenabled = 1;

  # Personalization
  networking.hostName = "zbook";
  system.defaults.dock.autohide = false;
  system.defaults.dock.orientation = "right";
  system.defaults.dock.tilesize = 35;
  system.defaults.finder._FXShowPosixPathInTitle = true;
  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.loginwindow.GuestEnabled = true;
  system.defaults.NSGlobalDomain._HIHideMenuBar = false;
  system.defaults.NSGlobalDomain.AppleShowScrollBars = "Always";
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
  system.defaults.NSGlobalDomain.KeyRepeat = 2;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;
  system.defaults.NSGlobalDomain.NSTableViewDefaultSizeMode = 2;
  system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint = true;
  system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint2 = true;
  system.defaults.trackpad.FirstClickThreshold = 0;
  system.defaults.trackpad.SecondClickThreshold = 0;
  system.keyboard.enableKeyMapping = true;
  system.keyboard.nonUS.remapTilde = true;
  system.defaults.screencapture.disable-shadow = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =[
    pkgs.asciinema
    pkgs.axel
    pkgs.bat
    pkgs.cachix
    pkgs.direnv
    pkgs.git
    pkgs.gitAndTools.diff-so-fancy
    pkgs.gnumake
    pkgs.gnupg
    pkgs.hyperfine
    pkgs.inetutils  # telnet has been renamed to/replaced by inetutils
    pkgs.jq
    pkgs.keybase
    pkgs.ncdu
    pkgs.ngrok
    pkgs.nix-direnv
    pkgs.nmap-unfree  # revert to pkgs.nmap in 21.09
    pkgs.pdfcrack
    pkgs.pgweb
    pkgs.prettyping
    pkgs.pwgen
    pkgs.python3
    pkgs.s3cmd
    pkgs.tldr
    pkgs.unrar
    pkgs.vim
    pkgs.wget
    (import (import /Users/zupo/.dotfiles/pins/nixpkgs_unstable.nix) {}).yt-dlp
  ];

  nix.extraOptions = ''
    # Support for https://github.com/nix-community/nix-direnv
    # nix options for derivations to persist garbage collection
    keep-outputs = true
    keep-derivations = true

    # Allow remote builders to use caches
    builders-use-substitutes = true

    # Support for `nix log`
    experimental-features = nix-command flakes
  '';
  environment.pathsToLink = [
    "/share/nix-direnv"
  ];

}
