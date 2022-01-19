{ config, pkgs, ... }:
let
  pgweb = pkgs.buildGoPackage rec {
    pname = "pgweb";
    version = "0.11.6";

    goPackagePath = "github.com/sosedoff/pgweb";

    src = pkgs.fetchFromGitHub {
      owner = "sosedoff";
      repo = "pgweb";
      rev = "v${version}";
      sha256 = "16qmc8c8vzs7zblmn7128bm91g6yvzrcapi6vlbjjbixqmzwfrcs";
    };
  };

in
{

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # Automatically manage build users
  users.nix.configureBuildUsers = true;

  # Automatically run `nix-store --optimize` to save disk space
  # nix.autoOptimiseStore = true;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 8;
  nix.buildCores = 8;

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

  # Support for nixbuild.net
  programs.ssh.knownHosts = {
    nixbuild = {
      hostNames = [ "eu.nixbuild.net" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };
  nix.distributedBuilds = true;
  nix.buildMachines = [
    { hostName = "eu.nixbuild.net";
      system = "x86_64-linux";
      maxJobs = 100;
      supportedFeatures = [ "benchmark" "big-parallel" "kvm" "nixos-test"];
    }
  ];

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
    pkgs.gitAndTools.diff-so-fancy
    pkgs.hyperfine
    pkgs.jq
    pkgs.ncdu

    # Apply https://github.com/NixOS/nixpkgs/pull/150791
    (pkgs.ngrok.overrideAttrs (oldAttrs: {
      dontStrip = true;
    }))

    pkgs.nix-direnv
    pkgs.nmap-unfree  # revert to pkgs.nmap in 21.09
    pkgs.prettyping
    pkgs.pwgen
    pkgs.s3cmd
    pkgs.telnet
    pkgs.tldr
    pkgs.unrar
    pkgs.vim
    pkgs.wget
    pkgs.yt-dlp

    pkgs.gnupg
    pkgs.keybase

    pgweb
  ];

  nix.extraOptions = ''
    # Support for https://github.com/nix-community/nix-direnv
    # nix options for derivations to persist garbage collection
    keep-outputs = true
    keep-derivations = true

    # Allow remote builders to use caches
    builders-use-substitutes = true
  '';
  environment.pathsToLink = [
    "/share/nix-direnv"
  ];

}
