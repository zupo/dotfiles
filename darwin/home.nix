{
  pkgs,
  lib,
  pkgsUnstable,
  commonModules,
  niteo-claude,
  llm-agents,
  ...
}:
{
  home.homeDirectory = lib.mkForce "/Users/zupo";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  # Tools that install themselves, like herdr's own installer
  home.sessionPath = [ "$HOME/.local/bin" ];

  imports = [
    (commonModules.ai {
      inherit
        pkgs
        pkgsUnstable
        niteo-claude
        llm-agents
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

      # `ssh cruncher` carries GitHub PATs for agent sessions on that host.
      # Tokens live only in 1Password on this Mac. The CLI authorization
      # (biometric prompt) lasts just long enough to read them -- signin,
      # read, signout -- then they ride along as env vars for the life of one
      # SSH session, never exported here, never written to disk anywhere.
      # Needs `AcceptEnv GH_TOKEN*` in cruncher's sshd config.
      ssh() {
        if (( ''${@[(I)cruncher]} )); then
          local teamniteo mayetrx
          op signin --account niteo.1password.com || return
          teamniteo=$(op read "op://Employee/zupo-agent-cruncher-teamniteo/credential")
          mayetrx=$(op read "op://Employee/zupo-agent-cruncher-mayetrx/credential")
          op signout
          [[ -n $teamniteo && -n $mayetrx ]] || { echo "ssh: failed to read GitHub tokens from 1Password" >&2; return 1; }
          GH_TOKEN_TEAMNITEO=$teamniteo GH_TOKEN_MAYETRX=$mayetrx GH_TOKEN=$teamniteo \
            command ssh -o 'SendEnv GH_TOKEN*' "$@"
        else
          command ssh "$@"
        fi
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
    pkgsUnstable.tailscale
    # 1Password CLI; pairs with the desktop app (Settings -> Developer ->
    # "Integrate with 1Password CLI") so `op read` unlocks via Touch ID.
    pkgsUnstable._1password-cli
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

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        ControlPath = "~/.ssh/master-%C";
        IdentityAgent = "/Users/zupo/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
        IgnoreUnknown = "UseKeychain";
        UseKeychain = "yes";
      };
      # MikroTik RouterOS/SwOS devices (see ~/work/house/network) will never
      # speak a post-quantum key exchange, so silence OpenSSH 10's noisy
      # "store now, decrypt later" warning for them. Real servers still warn.
      "router wifi_*" = {
        PubkeyAcceptedAlgorithms = "+ssh-rsa";
        WarnWeakCrypto = "no";
      };
      "localhost" = {
        StrictHostKeyChecking = "no";
        UserKnownHostsFile = "/dev/null";
      };
      "desktop" = {
        HostName = "192.168.65.8";
        ForwardAgent = true;
      };
      "cruncher" = {
        HostName = "cruncher";
        ForwardAgent = true;
      };
      "ai-zupo" = {
        HostName = "ai-zupo.containers";
        ProxyJump = "cruncher";
      };
      "cione" = {
        HostName = "cione";
        ForwardAgent = true;
      };
      "citwo" = {
        HostName = "citwo";
        ForwardAgent = true;
      };
      "cithree" = {
        HostName = "cithree";
        ForwardAgent = true;
      };
      "lara" = {
        HostName = "lara";
        # IdentityAgent = "SSH_AUTH_SOCK";
        # IdentityFile = "~/.ssh/id_rsa";
        # IdentitiesOnly = true;
        ForwardAgent = true;
      };
      "tailes" = {
        HostName = "tailes";
        IdentityAgent = "SSH_AUTH_SOCK";
        IdentityFile = "~/.ssh/id_rsa";
        IdentitiesOnly = true;
        ForwardAgent = true;
      };
      "tailsi" = {
        HostName = "tailsi";
        IdentityAgent = "SSH_AUTH_SOCK";
        IdentityFile = "~/.ssh/id_rsa";
        IdentitiesOnly = true;
        ForwardAgent = true;
      };
    };

  };
}
