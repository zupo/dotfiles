  {
    description = "zupo's macOS/Darwin system configuration";

    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
      nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
      home-manager.url = "github:nix-community/home-manager/release-24.11";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nix-darwin, home-manager }:
    let
      secrets = import /Users/zupo/.dotfiles/secrets.nix;

      gitconfig = { lib, ... }:{
        programs.git = {
          enable = true;
          diff-so-fancy.enable = true;
          userName = "Neyts Zupan";
          userEmail = secrets.email;
          attributes = [
            "*.bmml binary" # Prevent XML diffs for Balsamiq Mockups files
          ];
          aliases = {
            ap = "add -p";
            cdiff = "diff --cached";
            sdiff = "diff --staged";
            st = "status";
            ci = "commit";
            cia = "commit -v -a";
            cp = "cherry-pick";
            br = "branch --sort=-committerdate";
            co = "checkout";
            df = "diff";
            dfs = "diff --staged";
            l = "log";
            ll = "log -p";
            rehab = "reset origin/main --hard";
            pom = "push origin main";
            latest = "for-each-ref --sort=-committerdate refs/heads/";
            cod = "checkout src/mayet/demo/";
            addd = "add src/mayet/demo/";

            # A log of commits indicating where various branches are currently pointing.
            lga = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative --branches --remotes";

            # "git weburl" prints the URL of the github project page for repositories hosted on github.
            weburl = "!git config --get remote.origin.url | sed -e 's/git:\\/\\/github.com/https:\\/\\/github.com/' -e 's/git@github.com:/https:\\/\\/github.com\\//' -e 's/\\.git$//'";
            # "git browse" opens the github project page of this repository in the browser.
            browse = "!open `git weburl`";

            # search for a specific line of code in all commits in the repo.
            # Example: to find when the line "constraint=someMethod," was commented out, use:
            # git search '#constraint=someMethod,'
            search = "!f() { git log -S$1 --pretty=oneline --abbrev-commit; }; f";
            demo-start = "checkout demo-start";
            demo-next = "!git checkout `git rev-list HEAD..demo-end | tail -1`";
            demo-prev = "checkout HEAD^";
            demo-diff = "diff HEAD^";
            demo-msg = "log -1 --pretty=%B";
          };
          ignores = [
            # Packages: it's better to unpack these files and commit the raw source
            # git has its own built in compression methods
            "*.7z"
            "*.dmg"
            "*.gz"
            "*.iso"
            "*.jar"
            "*.rar"
            "*.tar"
            "*.zip"

            # OS generated files
            ".DS_Store"
            ".DS_Store?"
            "ehthumbs.db"
            "Icon?"
            "Thumbs.db"

            # Sublime
            "sublime/*.cache"
            "sublime/oscrypto-ca-bundle.crt"
            "sublime/Package Control.last-run"
            "sublime/Package Control.merged-ca-bundle"
            "sublime/Package Control.user-ca-bundle"

            # VS Code
            "vscode/History/"
            "vscode/globalStorage/"
            "vscode/workspaceStorage/"

            # Secrets
            "ssh_config_private"
          ];
          extraConfig = {
            branch = {
              autosetuprebase = "always";
            };
            credential = {
              helper = "osxkeychain";
            };
            github = {
              user = "zupo";
              token = secrets.github.token;
            };
            help = {
              autocorrect = 1;
            };
            init = {
              defaultBranch = "main";
            };
            push = {
              default = "simple";
            };
          };
        };
      };

      homeconfig = { pkgs, lib, ... }: {
        home.homeDirectory = lib.mkForce "/Users/zupo";
        home.stateVersion = "23.11";
        programs.home-manager.enable = true;

        imports = [ gitconfig ];

        # Software I can't live without
        home.packages = with pkgs; [
          (import nixpkgs-unstable { system = "aarch64-darwin"; }).devenv
          (import nixpkgs-unstable { system = "aarch64-darwin"; config.allowUnfree = true; }).claude-code
          pkgs.asciinema
          pkgs.axel
          pkgs.bat
          pkgs.cachix
          pkgs.gnumake
          pkgs.gnupg
          pkgs.hyperfine
          pkgs.inetutils  # telnet
          pkgs.jq
          pkgs.keybase
          pkgs.ncdu
          pkgs.ngrok
          pkgs.nix-init
          pkgs.nixd
          pkgs.nixfmt-rfc-style
          pkgs.nmap
          pkgs.pdfcrack
          pkgs.pgweb
          pkgs.prettyping
          pkgs.pwgen
          pkgs.python3
          pkgs.s3cmd
          pkgs.tailscale
          pkgs.tldr
          pkgs.unrar
          pkgs.wget
          pkgs.yt-dlp
        ];

        programs.vim.enable = true;

        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        programs.ssh = {
          enable = true;
          addKeysToAgent = "yes";

          # OK so this one is a bit convoluted:
          # I want to forward the agent to my desktop, but not to other hosts.
          # However, homemanager puts `Host *` with ForwardAgent at the top of the
          # ssh config file, and that takes precedence over the more specific
          # `Host desktop` configuration lower in the file.
          # The solution is to disable ForwardAgent for all hosts, and then enable
          # it for the desktop host, and then disable again it for all other hosts.
          forwardAgent = true;

          extraConfig = ''
            IgnoreUnknown UseKeychain
            UseKeychain yes

            # Support connecting to RouterOS v6 Mikrotik devices
            PubkeyAcceptedAlgorithms +ssh-rsa

            # Enable SSH agent forwarding to the desktop VM
            Host desktop
              ForwardAgent yes

            # Disable SSH agent forwarding for all other hosts
            Host *
              ForwardAgent no

            # Skip host key checking for NixOS Tests VMs
            Host localhost
              StrictHostKeyChecking no
              UserKnownHostsFile /dev/null

            # Save IP of the desktop VM
            Host desktop
              HostName 192.168.64.10
          '';
        };

        programs.zsh = {
          enable = true;
          autosuggestion.enable = true;
          enableCompletion = true;
          oh-my-zsh = {
            enable = true;
            theme = "robbyrussell";
            plugins = ["git" "python" "sudo" "direnv"];
          };
          sessionVariables = {
            LC_ALL = "en_US.UTF-8";
            LANG = "en_US.UTF-8";
            EDITOR = "~/.editor";

            # Needed for synologycloudsyncdecryptiontool
            PATH = "$PATH:$HOME/bin";

            # Enable a few neat OMZ features
            HYPHEN_INSENSITIVE = "true";
            COMPLETION_WAITING_DOTS = "true";

            # Disable generation of .pyc files
            # https://docs.python-guide.org/writing/gotchas/#disabling-bytecode-pyc-files
            PYTHONDONTWRITEBYTECODE = "0";
          };
          shellAliases = {
            axel = "axel -a";
            rsync = "rsync -avzhP";
            pwgen = "pwgen --ambiguous 20";
            cat = "bat";
            ping = "prettyping --nolegend";
            diff = "diff-so-fancy";
            man = "tldr";
            subl = "code";
            nixre = "darwin-rebuild switch --flake ~/.dotfiles#zbook --impure";
            nixgc = "nix-collect-garbage -d";
            nixcfg = "code ~/.dotfiles/flake.nix";
            yt-dlp-lowres = "yt-dlp -S res:720";
          };
          history = {
            append = true;
            share = true;
          };
          initExtra = ''
            function edithosts {
                sudo vim /etc/hosts && echo "* Successfully edited /etc/hosts"
                sudo dscacheutil -flushcache && echo "* Flushed local DNS cache"
            }
          '';
        };

        # Don't show the "Last login" message for every new terminal.
        home.file.".hushlogin" = {
          text = "";
        };

        home.file.".editor" = {
          executable = true;
          text = ''
            #!/bin/bash
            # https://github.com/microsoft/vscode/issues/68579#issuecomment-463039009
            code --wait "$@"
            open -a Terminal
          '';
        };
        
      };

      configuration = { pkgs, ... }: {

        # Use nix from pinned nixpkgs
        services.nix-daemon.enable = true;
        nix.settings.trusted-users = [ "@admin" ];
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
          "https://niteo.cachix.org"
        ];
        nix.settings.trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
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

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true;

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
        modules = [
          configuration
          home-manager.darwinModules.home-manager  {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.zupo = homeconfig;
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."zbook".pkgs;

      # Support using parts of the config elsewhere
      homeconfig = homeconfig;
      gitconfig = gitconfig;
    };
  }
