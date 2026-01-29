{
  pkgs,
  lib,
  pkgsUnstable,
  commonModules,
  niteo-claude,
  ...
}:
{
  home.homeDirectory = lib.mkForce "/Users/zupo";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  imports = [
    (commonModules.ai {
      inherit
        pkgs
        pkgsUnstable
        niteo-claude
        lib
        ;
    })
    commonModules.direnv
    commonModules.files
    commonModules.gitconfig
    commonModules.vim
    commonModules.zsh
    (commonModules.tools {
      inherit pkgs pkgsUnstable;
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
      nixre = "sudo darwin-rebuild switch --flake ~/work/dotfiles#zbook";
      nixgc = "nix-collect-garbage --delete-older-than 30d";
      nixcfg = "code ~/work/dotfiles/flake.nix";
      yt-dlp-lowres = "yt-dlp -S res:720";
      yt-dlp-audio = "yt-dlp --extract-audio --audio-format mp3";
    };

    initContent = ''
      # Source secrets if available
      [[ -f ~/work/dotfiles/.secrets.env ]] && source ~/work/dotfiles/.secrets.env

      function edithosts {
         sudo vim /etc/hosts && echo "* Successfully edited /etc/hosts"
         sudo dscacheutil -flushcache && echo "* Flushed local DNS cache"
      }
    '';
  };

  # Additional Mac-specific git configuration
  programs.git.settings = {
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
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        controlPath = "~/.ssh/master-%C";
        identityAgent = "/Users/zupo/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
        extraOptions = {
          "IgnoreUnknown" = "UseKeychain";
          "UseKeychain" = "yes";
          # Support connecting to RouterOS v6 Mikrotik devices
          "PubkeyAcceptedAlgorithms" = "+ssh-rsa";
        };
      };
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

  };
}
