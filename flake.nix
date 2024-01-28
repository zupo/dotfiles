{
  description = "zupo's macOS/Darwin system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {

      # Software I can't live without:
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
        pkgs.inetutils  # telnet
        pkgs.jq
        pkgs.keybase
        pkgs.ncdu
        pkgs.ngrok
        pkgs.nix-direnv
        pkgs.nmap
        pkgs.pdfcrack
        pkgs.pgweb
        pkgs.prettyping
        pkgs.pwgen
        pkgs.python3
        pkgs.s3cmd
        pkgs.tldr
        pkgs.unrar
        pkgs.wget
        # (import (import /Users/zupo/.dotfiles/pins/nixpkgs_unstable.nix) {}).yt-dlp
      ];

      # Use nix from pinned nixpkgs.
      services.nix-daemon.enable = true;
      nix.settings.trusted-users = [ "root" "zupo" ];
      nix.package = pkgs.nix;

      # Using flakes instead of channels
      nix.settings.nix-path = ["nixpkgs=flake:nixpkgs"];

      # Allow licensed binaries
      nixpkgs.config.allowUnfree = true;

      # Automatically run `nix-store --optimize` to save disk space
      nix.settings.auto-optimise-store = true;

      # Longer log output on errors
      nix.settings.log-lines = 25;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Configure Cachix
      nix.settings.substituters = [
        "https://cache.nixos.org"
        "https://niteo.cachix.org"
      ];
      nix.settings.trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "niteo.cachix.org-1:GUFNjJDCE199FDtgkG3ECLrAInFZEDJW2jq2BUQBFYY="
      ];
      nix.settings.netrc-file = "/Users/zupo/.config/nix/netrc";

      # Allow remote builders to use caches
      nix.extraOptions = ''
        builders-use-substitutes = true
      '';

      # Sane vim defaults
      programs.vim.enable = true;
      programs.vim.enableSensible = true;

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;
      programs.zsh.enableSyntaxHighlighting = true;

      # Don't show the "Last login" message for every new terminal.
      environment.etc.hushlogin.enable = true;

      # Default prompt includes `prompt walters` that adds an annoying
      # "current path" info to the right of the terminal line, which makes
      # copy/pasting terminal output a pain
      programs.zsh.promptInit = "autoload -U promptinit && promptinit";

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 4;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Use TouchID for sudo
      security.pam.enableSudoTouchIdAuth = true;

      # make sure firewall is up & running
      system.defaults.alf.globalstate = 1;
      system.defaults.alf.stealthenabled = 1;

      # Personalization
      networking.hostName = "zbook";
      system.defaults.dock.autohide = true;
      system.defaults.dock.orientation = "right";
      system.defaults.dock.tilesize = 35;
      system.defaults.finder._FXShowPosixPathInTitle = true;
      system.defaults.finder.AppleShowAllExtensions = true;
      system.defaults.finder.AppleShowAllFiles = true;
      system.defaults.finder.ShowPathbar = true;
      system.defaults.finder.ShowStatusBar = true;
      system.defaults.finder.FXPreferredViewStyle = "clmv";
      system.defaults.loginwindow.GuestEnabled = true;
      system.defaults.finder.FXDefaultSearchScope = "SCcf"; # search current folder by default
      system.defaults.NSGlobalDomain.AppleShowScrollBars = "Always";
      system.defaults.NSGlobalDomain.AppleScrollerPagingBehavior = true;
      system.defaults.finder.FXEnableExtensionChangeWarning = false;
      system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
      system.defaults.NSGlobalDomain.KeyRepeat = 2;
      system.defaults.NSGlobalDomain.AppleKeyboardUIMode = 3;
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
      system.defaults.screensaver.askForPasswordDelay = 10;
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .
    # $ nix run nix-darwin -- switch --flake .#zbook
    darwinConfigurations."zbook" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."simple".pkgs;
  };
}
