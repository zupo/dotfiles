{
  pkgs,
  lib,
  pkgsUnstable,
  commonModules,
  mcp-nixos,
  ...
}:
{
  home.homeDirectory = lib.mkForce "/Users/zupo";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  imports = [
    commonModules.direnv
    commonModules.files
    commonModules.gitconfig
    commonModules.vim
    commonModules.zsh
    (commonModules.tools {
      inherit pkgs;
      inherit pkgsUnstable;
      inherit mcp-nixos;
    })

  ];

  # Additional Darwin-specific zsh configuration
  programs.zsh = {
    sessionVariables = {
      # Use VSCode as the default editor, but wrapped so it returns focus
      # to the terminal after editing.
      EDITOR = "~/.editor";

      # Needed for synologycloudsyncdecryptiontool
      PATH = "$PATH:$HOME/bin";

      # OpenAI API key is loaded from .secrets.env
    };

    # Additional Mac-specific aliases
    shellAliases = {
      subl = "code";
      nixre = "sudo darwin-rebuild switch --flake ~/.dotfiles#zbook";
      nixgc = "nix-collect-garbage -d";
      nixcfg = "code ~/.dotfiles/flake.nix";
      yt-dlp-lowres = "yt-dlp -S res:720";
      yt-dlp-audio = "yt-dlp --extract-audio --audio-format mp3";
    };

    initContent = ''
      # Source secrets if available
      [[ -f ~/.dotfiles/.secrets.env ]] && source ~/.dotfiles/.secrets.env

      function edithosts {
         sudo vim /etc/hosts && echo "* Successfully edited /etc/hosts"
         sudo dscacheutil -flushcache && echo "* Flushed local DNS cache"
      }
    '';
  };

  # Additional Mac-specific git configuration
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
      open -a Ghostty
    '';
  };

  # Ghostty terminal configuration
  home.file.".config/ghostty/config".text = ''
    theme = Dark Modern

    # Uncomment when https://github.com/ghostty-org/ghostty/issues/1392 is fixed
    # window-inherit-working-directory = false
  '';

  # SSH client config on the Mac
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    controlPath = "~/.ssh/master-%C";

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
        hostname = "cruncher.niteo.co";
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
      # Include private SSH config
      Include ~/.dotfiles/.secrets.ssh

      IgnoreUnknown UseKeychain
      UseKeychain yes

      # Support connecting to RouterOS v6 Mikrotik devices
      PubkeyAcceptedAlgorithms +ssh-rsa

      # TODO: Rewrite to programs.ssh.idenityAgent = ... when 25.11 is released
      Host *
      	IdentityAgent /Users/zupo/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
    '';
  };
}
