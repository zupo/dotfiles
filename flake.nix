{
  description = "zupo's macOS/Darwin system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nixpkgs-unstable }:
  let
    configuration = { pkgs, ... }: {

      # Software I can't live without
      environment.systemPackages =[
        pkgs.asciinema
        pkgs.axel
        pkgs.bat
        pkgs.cachix
        (nixpkgs-unstable.legacyPackages.${pkgs.system}.devenv)
        pkgs.direnv
        pkgs.git
        pkgs.gitAndTools.diff-so-fancy
        pkgs.gnumake
        pkgs.gnupg
        pkgs.hyperfine
        pkgs.inetutils  # telnet
        pkgs.jq
        pkgs.keybase
        # pkgs.ncdu  # uncomment when this is fixed: https://github.com/NixOS/nixpkgs/issues/287861
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
        (nixpkgs-unstable.legacyPackages.${pkgs.system}.yt-dlp)
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

      # Sane vim defaults
      programs.vim.enable = true;
      programs.vim.enableSensible = true;

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

        # Tell zsh to update the history file after every command,
        # rather than waiting for the shell to exit:
        setopt INC_APPEND_HISTORY

        # Change /etc/hosts and flush DNS cache
        function edithosts {
            sudo vim /etc/hosts && echo "* Successfully edited /etc/hosts"
            sudo dscacheutil -flushcache && echo "* Flushed local DNS cache"
        }
      '';
      programs.zsh.variables = {
        EDITOR = "~/.dotfiles/editor.sh";
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

      # Open GitX from Terminal, taken from
      # https://stackoverflow.com/questions/11625836/make-gitx-open-via-terminal-for-the-repo-laying-at-the-current-path
      # environment.shellAliases.gitx = "open -a GitX .";

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
      environment.shellAliases.nixre = "darwin-rebuild switch --flake ~/.dotfiles#zbook";
      environment.shellAliases.nixgc = "nix-collect-garbage -d";
      environment.shellAliases.nixcfg = "code ~/.nixpkgs/darwin-configuration.nix";

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

      # Configure git
      environment.etc.gitattributes.text = ''
        # Prevent XML diffs for Balsamiq Mockups files
        *.bmml binary
      '';
      environment.etc.gitignore.text = ''
        # Packages #
        ############
        # it's better to unpack these files and commit the raw source
        # git has its own built in compression methods
        *.7z
        *.dmg
        *.gz
        *.iso
        *.jar
        *.rar
        *.tar
        *.zip

        # OS generated files #
        ######################
        .DS_Store
        .DS_Store?
        ehthumbs.db
        Icon?
        Thumbs.db

        # Sublime #
        ###########
        sublime/*.cache
        sublime/oscrypto-ca-bundle.crt
        sublime/Package Control.last-run
        sublime/Package Control.merged-ca-bundle
        sublime/Package Control.user-ca-bundle

        # VS Code #
        ##########
        vscode/History/
        vscode/globalStorage/
        vscode/workspaceStorage/

        # Secrets #
        ###########
        ssh_config_private
      '';
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
