  {
    description = "zupo's macOS/Darwin system configuration";

    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
      nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      nixpkgs-master.url = "github:NixOS/nixpkgs/master";
      nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
      home-manager.url = "github:nix-community/home-manager/release-25.05";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
      mcp-nixos.url = "github:utensils/mcp-nixos";
      mcp-nixos.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nixpkgs-master, nix-darwin, home-manager, mcp-nixos }:
    let

      gitconfig = { email }: import ./gitconfig.nix {
        email = email;
      };

      tools = { pkgs, pkgsUnstable, pkgsMaster,... }: import ./tools.nix {
        pkgs = pkgs;
        pkgsUnstable = pkgsUnstable;
        pkgsMaster = pkgsMaster;
        mcp-nixos = mcp-nixos;
      };

      direnv = { ... }: import ./direnv.nix { };

      vim = { ... }: import ./vim.nix { };

      zsh = { ... }: import ./zsh.nix { };

      files = { ... }: import ./files.nix { };

      homeconfig = let

          # I want to keep my secrets out of git, so I need to run flakes
          # with the --impure flag.
          secrets = import /Users/zupo/.dotfiles/secrets.nix;

      in
      { pkgs, lib, pkgsUnstable, pkgsMaster, ... }: {
        home.homeDirectory = lib.mkForce "/Users/zupo";
        home.stateVersion = "23.11";
        programs.home-manager.enable = true;

        imports = [
          direnv
          vim
          zsh
          files
          (tools { pkgs = pkgs; pkgsUnstable = pkgsUnstable; pkgsMaster = pkgsMaster; })
          (gitconfig { email = secrets.email; })
        ];

        # Additional Darwin-specific zsh configuration
        programs.zsh =
        {

          sessionVariables = {
            # Use VSCode as the default editor, but wrapped so it returns focus
            # to the terminal after editing.
            EDITOR = "~/.editor";

            # Needed for synologycloudsyncdecryptiontool
            PATH = "$PATH:$HOME/bin";

            # OpenAI Codex
            OPENAI_API_KEY = secrets.openai_api_key;
          };

          shellAliases = {
            subl = "code";
            nixre = "sudo darwin-rebuild switch --flake ~/.dotfiles#zbook --impure";
            nixgc = "nix-collect-garbage -d";
            nixcfg = "code ~/.dotfiles/flake.nix";
            yt-dlp-lowres = "yt-dlp -S res:720";
            yt-dlp-audio = "yt-dlp --extract-audio --audio-format mp3";
          };

          initContent = ''
            function edithosts {
               sudo vim /etc/hosts && echo "* Successfully edited /etc/hosts"
               sudo dscacheutil -flushcache && echo "* Flushed local DNS cache"
           }
          '';
        };

        # Additional Darwin-specific git configuration
        programs.git.extraConfig = {
          credential = {
            helper = "osxkeychain";
          };
        };

        # Additional software I use on my Mac
        home.packages = with pkgs; [
          # pkgsUnstable.tailscale
          harper
          keybase
          yt-dlp
        ];


        # Use VSCode as the default editor on the Mac
        home.file.".editor" = {
          executable = true;
          text = ''
            #!/bin/bash
            # https://github.com/microsoft/vscode/issues/68579#issuecomment-463039009
            code --wait "$@"
            open -a Terminal
          '';
        };

        # SSH client config on the Mac
        programs.ssh =
        let
          secrets = import /Users/zupo/.dotfiles/secrets.nix;
        in {
          enable = true;
          addKeysToAgent = "yes";

          matchBlocks = {
            "localhost" = {
              extraOptions = {
                "StrictHostKeyChecking" = "no";
                "UserKnownHostsFile" = "/dev/null";
              };
            };
            "desktop" = {
              hostname = "192.168.65.8";
              forwardAgent = true;
            };
            "cruncher" = {
              hostname= secrets.cruncher.ip;
              forwardAgent = true;
              extraOptions = {
                "PermitLocalCommand" = "yes";
                "LocalCommand" = ''
                osascript -e 'tell application "Terminal" to set current settings of front window to settings set "Novel"'
              '';
              };
            };
          };

          extraConfig = ''
            IgnoreUnknown UseKeychain
            UseKeychain yes

            # Support connecting to RouterOS v6 Mikrotik devices
            PubkeyAcceptedAlgorithms +ssh-rsa

            # TODO: Rewrite to programs.ssh.idenityAgent = ... when 25.11 is released
            Host *
            	IdentityAgent /Users/zupo/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
          '';
        };

      };

      configuration = { pkgs, ... }: {

        # Use nix from pinned nixpkgs
        nix.settings.trusted-users = [ "@admin zupo" ];
        nix.package = pkgs.nix;

        # Using flakes instead of channels
        nix.settings.nix-path = ["nixpkgs=flake:nixpkgs"];

        # Allow licensed binaries
        nixpkgs.config.allowUnfree = true;

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
        ];
        nix.settings.trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "niteo.cachix.org-1:GUFNjJDCE199FDtgkG3ECLrAInFZEDJW2jq2BUQBFYY="
        ];
        nix.settings.netrc-file = "/Users/zupo/.config/nix/netrc";

        # Support for building Linux binaries
        nix.linux-builder = {
          enable = true;
          ephemeral = true;
          maxJobs = 4;
          config = {
            virtualisation = {
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

        # Enable logging for the linux builder
        launchd.daemons.linux-builder = {
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

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";

        # Use TouchID for sudo
        security.pam.services.sudo_local.touchIdAuth = true;

        # make sure firewall is up & running
        system.defaults.alf.globalstate = 1;
        system.defaults.alf.stealthenabled = 1;

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

      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake . --impure
      # $ nix run nix-darwin -- switch --flake .#zbook
      darwinConfigurations."zbook" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager  {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.zupo = homeconfig;
              home-manager.extraSpecialArgs = {
                pkgsUnstable = import nixpkgs-unstable {
                  system = "aarch64-darwin";
                  config.allowUnfree = true;
                };
                pkgsMaster = import nixpkgs-master {
                  system = "aarch64-darwin";
                  config.allowUnfree = true;
                };
              };
          }
        ];
      };

      # Support using parts of the config elsewhere
      direnv = direnv;
      files = files;
      gitconfig = gitconfig;
      tools = tools;
      vim = vim;
      zsh = zsh;
    };
  }
