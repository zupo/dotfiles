{
  config,
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:
{

  # Use nix from pinned nixpkgs
  nix.settings.trusted-users = [ "@admin zupo" ];
  nix.package = pkgs.nix;

  # Using flakes instead of channels
  nix.settings.nix-path = [ "nixpkgs=flake:nixpkgs" ];

  # Allow licensed binaries
  nixpkgs.config.allowUnfree = true;

  # Fix direnv build on macOS:
  # - CGO_ENABLED=1 required for -linkmode=external
  # - fish test gets SIGKILL'd in the sandbox
  nixpkgs.overlays = [
    (_final: prev: {
      direnv = prev.direnv.overrideAttrs (old: {
        env = (old.env or { }) // {
          CGO_ENABLED = 1;
        };
        checkPhase = builtins.replaceStrings [ "test-fish" ] [ "" ] (old.checkPhase or "");
      });
    })
  ];

  # Save disk space
  nix.optimise.automatic = true;

  # Longer log output on errors
  nix.settings.log-lines = 25;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Configure Cachix
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://devenv.cachix.org"
    "https://niteo.cachix.org"
    "https://cache.numtide.com"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    "niteo.cachix.org-1:GUFNjJDCE199FDtgkG3ECLrAInFZEDJW2jq2BUQBFYY="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];
  nix.settings.netrc-file = "/Users/zupo/.config/nix/netrc";

  # Native ARM Linux builds and nested KVM for NixOS integration tests (M3+).
  nix.linux-builder = {
    enable = true;
    package = pkgsUnstable.darwin.linux-builder-vz;
    ephemeral = true;
    maxJobs = 4;
    supportedFeatures = [
      "kvm"
      "nixos-test"
      "benchmark"
      "big-parallel"
    ];
    config = {
      virtualisation = {
        vz = {
          nestedVirtualization = true;
          rosetta.enable = false;
        };
        darwin-builder = {
          diskSize = 40 * 1024;
          memorySize = 8 * 1024;
        };
        cores = 6;
      };
    };
  };

  # Migration to 25.05, remove after clean reinstall
  ids.gids.nixbld = 350;

  # Enable logging for the linux builder. Only while the builder is on: on its
  # own this would define a daemon with no program, which launchd rejects.
  launchd.daemons.linux-builder = lib.mkIf config.nix.linux-builder.enable {
    serviceConfig = {
      StandardOutPath = "/var/log/darwin-builder.log";
      StandardErrorPath = "/var/log/darwin-builder.log";
    };
  };

  # Increase file descriptor limits
  launchd.daemons.limit-maxfiles = {
    command = "launchctl limit maxfiles 65536 524288";
    serviceConfig.RunAtLoad = true;
    serviceConfig.KeepAlive = false;
  };

  # Allow remote builders to use caches
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Use TouchID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Distrust roots of the compromised eMudhra intermediates (Oct 2026), as CLI
  # tools reading /etc/ssl/certs/ca-certificates.crt never check revocation.
  # Names as they appear in that file.
  # https://paretosecurity.com/mac/checks/compromised-ca
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root" # AAA Certificate Services
    "emSign ECC Root CA - G3"
  ];

  # make sure firewall is up & running
  networking.applicationFirewall.enable = true;
  networking.applicationFirewall.enableStealthMode = true;

  # nix-darwin resets PATH to a fixed list on every shell start, which drops
  # the `rex` CLI the Rex terminal injects. Put it back in every interactive
  # bash and zsh, as its docs ask: https://www.superlogical.com/rex/docs/installation
  environment.interactiveShellInit = ''
    if [ -n "$REX_BIN_DIR" ]; then
      export PATH="$REX_BIN_DIR:$PATH"
    fi
  '';

  # Nerd Fonts for terminal icons (lsd, etc.)
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg # same as default macOS "Menlo" font
    # Terminal -> Settings -> Text -> Font: MesloLGS Nerd Font Regular 12
  ];

  # Personalization
  system.primaryUser = "zupo";
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
}
