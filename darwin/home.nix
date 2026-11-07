{
  config,
  pkgs,
  lib,
  pkgsUnstable,
  commonModules,
  niteo-agents,
  llm-agents,
  passlet,
  ...
}:
{
  home.homeDirectory = lib.mkForce "/Users/zupo";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  # Tools that install themselves (uv-managed pythons, …)
  home.sessionPath = [ "$HOME/.local/bin" ];
  home.file.".local/bin/tailscale" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec /Applications/Tailscale.app/Contents/MacOS/Tailscale "$@"
    '';
  };

  imports = [
    passlet.homeManagerModules.default
    (commonModules.ai {
      inherit
        pkgs
        pkgsUnstable
        niteo-agents
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

  programs.passlet = {
    enable = true;
    service.tailscale = true;
  };

  # Additional Darwin-specific zsh configuration
  programs.zsh = {
    sessionVariables = {
      # Use VSCode as the default editor, but wrapped so it returns focus
      # to Rex after editing.
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
    # 1Password CLI; pairs with the desktop app (Settings -> Developer ->
    # "Integrate with 1Password CLI") so `op read` unlocks via Touch ID.
    pkgsUnstable._1password-cli
    harper
    keybase
    yt-dlp

    # `rex-open <name>`: bring ~/work/<name> to a fresh origin/main (or clone
    # it from teamniteo/mayetrx), name the current Rex session after it, then
    # cd there and start claude in this terminal.
    # `rex` is not a nix package; it resolves from the PATH Rex injects.
    (writeShellApplication {
      name = "rex-open";
      runtimeInputs = [
        git
        gh
        jq
        direnv
      ];
      text = builtins.readFile ./rex-open.sh;
    })
  ];

  # Use VSCode as the default editor on the Mac
  home.file.".editor" = {
    executable = true;
    text = ''
      #!/bin/bash
      # https://github.com/microsoft/vscode/issues/68579#issuecomment-463039009
      code --wait "$@"
      # Rex, by bundle id so the app name ("Rex Beta" today) does not matter.
      open -b com.superlogical.rex
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
      "sandbox-zupo" = {
        ControlMaster = "auto";
        ControlPersist = "10m";
        ExitOnForwardFailure = true;
        HostName = "sandbox-zupo.containers";
        ProxyJump = "cruncher";
        RemoteForward = "/home/zupo/.local/share/passlet/passlet.sock /Users/zupo/.local/share/passlet/passlet.sock";
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
