{
  description = "zupo's macOS/Darwin system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager }:
  let
    secrets = import /Users/zupo/.dotfiles/secrets.nix;

    home-config = { pkgs, lib, ... }: {
      home.username = "zupo";
      home.homeDirectory = lib.mkForce "/Users/zupo";
      home.stateVersion = "23.11";
      programs.home-manager.enable = true;

      # Software I can't live without
      home.packages = with pkgs; [
        pkgs.asciinema
        pkgs.axel
        pkgs.bat
        pkgs.cachix
        pkgs.devenv
        pkgs.direnv
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
        pkgs.tailscale
        pkgs.tldr
        pkgs.unrar
        pkgs.wget
        pkgs.yt-dlp
      ];

      programs.vim = {
        enable = true;
        defaultEditor = true;
      };

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

    system-config = { pkgs, ... }: {

      # Use Home Manger to configure the user environment
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.zupo = home-config;
      };

      # Use nix from pinned nixpkgs
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

      # Support for building Linux binaries
      # nix.linux-builder.enable = true;

      # Allow remote builders to use caches
      nix.extraOptions = ''
        builders-use-substitutes = true
      '';

      # Enable nix-direnv
      environment.pathsToLink = [
        "/share/nix-direnv"
      ];
      environment.extraInit = ''
        cat > /Users/zupo/.config/nix-direnv/direnvrc << EOF
        # This is managed by ~/.dotfiles/flake.nix, any change will be overwritten
        source /run/current-system/sw/share/nix-direnv/direnvrc
        EOF

        cat > /Users/zupo/.zshrc << EOF
        # This is managed by ~/.dotfiles/flake.nix, any change will be overwritten
        source /Users/zupo/.oh-my-zsh/oh-my-zsh.sh
        EOF
      '';

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;
      programs.zsh.enableSyntaxHighlighting = true;
      programs.zsh.interactiveShellInit = ''
        # Which plugins would you like to load?
        # Standard plugins can be found in ~/.oh-my-zsh/plugins/*
        # Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
        # Example format: plugins=(rails git textmate ruby lighthouse)
        # Add wisely, as too many plugins slow down shell startup.
        plugins=(git python sudo direnv history)

        # By default, when you exit zsh this particular instance of zsh
        # will overwrite an existing history file with its history. So
        # when you have multiple tabs open, they will all overwrite
        # each others’ histories eventually. Tell zsh to use a single,
        # shared history file across the sessions and append to it
        # rather than overwrite. Additionally, append as soon as commands are entered
        # rather than waiting until the shell exits
        setopt INC_APPEND_HISTORY


        # Change /etc/hosts and flush DNS cache
        function edithosts {
            sudo vim /etc/hosts && echo "* Successfully edited /etc/hosts"
            sudo dscacheutil -flushcache && echo "* Flushed local DNS cache"
        }
      '';
      programs.zsh.variables = {
        # EDITOR = "~/.dotfiles/editor.sh";
        LC_ALL = "en_US.UTF-8";
        LANG = "en_US.UTF-8";
        PATH = "$PATH:$HOME/bin";

        # Enable OMZ
        ZSH = "/Users/zupo/.oh-my-zsh";

        # Use the default theme that comes with oh-my-zsh
        ZSH_THEME = "robbyrussell";

        # Enable a few neat features
        HYPHEN_INSENSITIVE = "true";
        COMPLETION_WAITING_DOTS = "true";

        # Disable generation of .pyc files
        # https://docs.python-guide.org/writing/gotchas/#disabling-bytecode-pyc-files
        PYTHONDONTWRITEBYTECODE = "0";
      };

      # Don't show the "Last login" message for every new terminal.
      environment.etc.hushlogin.enable = true;

      # Default prompt includes `prompt walters` that adds an annoying
      # "current path" info to the right of the terminal line, which makes
      # copy/pasting terminal output a pain
      programs.zsh.promptInit = "autoload -U promptinit && promptinit";

      # Show alternative progress bar for Axel downloader
      environment.shellAliases.axel = "axel -a";

      # rsync sane defaults
      environment.shellAliases.rsync = "rsync -avzhP";

      # Force strong passwords
      environment.shellAliases.pwgen = "pwgen --ambiguous 20";

      # Better alternatives of common CLI commands
      # (Inspired by https://remysharp.com/2018/08/23/cli-improved)
      #
      # Escape hatch: use `\`
      # \cat # ignore aliases named "cat"
      environment.shellAliases.cat = "bat";
      environment.shellAliases.ping = "prettyping --nolegend";
      environment.shellAliases.diff = "diff-so-fancy";
      environment.shellAliases.man = "tldr";
      environment.shellAliases.subl = "code";

      # nix-darwin shortcuts
      # we need --impure because we're using flakes and secrets.nix
      environment.shellAliases.nixre = "darwin-rebuild switch --flake ~/.dotfiles#zbook --impure";
      environment.shellAliases.nixgc = "nix-collect-garbage -d";
      environment.shellAliases.nixcfg = "code ~/.dotfiles/flake.nix";

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
      modules = [ system-config home-manager.darwinModule ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."zbook".pkgs;
  };
}
