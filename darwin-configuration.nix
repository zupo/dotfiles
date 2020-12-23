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
    pkgs.direnv
    pkgs.gitAndTools.diff-so-fancy
    pkgs.jq
    pkgs.cachix
    pkgs.ncdu
    pkgs.ngrok
    pkgs.nmap
    pkgs.prettyping
    pkgs.pwgen
    pkgs.s3cmd
    pkgs.telnet
    pkgs.tldr
    # pkgs.unrar
    pkgs.vim
    pkgs.wget
    pkgs.youtube-dl
    pkgs.nix-direnv

    pgweb
  ];

  # nmap 7.80 that currently ships with 20.09 has the following bug on Big Sur:
  # https://github.com/nmap/nmap/issues/2079
  # And it doesn't seem like it will get updated soon due to licensing issues:
  # https://github.com/NixOS/nixpkgs/issues/105119
  nixpkgs.config.packageOverrides = pkgs: rec {
    nmap = pkgs.stdenv.lib.overrideDerivation pkgs.nmap (oldAttrs: {
      name = "nmap-7.91";

      src = pkgs.fetchurl {
        url = "https://nmap.org/dist/nmap-7.91.tar.bz2";
        sha256 = "001kb5xadqswyw966k2lqi6jr6zz605jpp9w4kmm272if184pk0q";
      };
    });
  };

  # Support for https://github.com/nix-community/nix-direnv
  # nix options for derivations to persist garbage collection
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
  environment.pathsToLink = [
    "/share/nix-direnv"
  ];

}
