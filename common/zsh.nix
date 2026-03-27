_: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "sudo"
        "direnv"
      ];
    };
    sessionVariables = {
      LC_ALL = "en_US.UTF-8";
      LANG = "en_US.UTF-8";

      # Enable a few neat OMZ features
      HYPHEN_INSENSITIVE = "true";
      COMPLETION_WAITING_DOTS = "true";

      # Disable generation of .pyc files
      # https://docs.python-guide.org/writing/gotchas/#disabling-bytecode-pyc-files
      PYTHONDONTWRITEBYTECODE = "0";
    };
    shellAliases = {
      axel = "axel -a";
      cat = "bat";
      diff = "diff-so-fancy";
      ls = "lsd";
      man = "tldr";
      ping = "prettyping --nolegend";
      pwgen = "pwgen --ambiguous 20";
      rsync = "rsync -avzhP";
    };
    history = {
      append = true;
      share = true;
    };
    initContent = ''
      eval "$(atuin init zsh --disable-up-arrow)"

      # Rewrite `git push -f` and `git push --force` to `git push --force-with-lease`
      git() {
        if [[ "$1" == "push" ]]; then
          local args=("push")
          shift
          for arg in "$@"; do
            case "$arg" in
              -f|--force) args+=("--force-with-lease") ;;
              *) args+=("$arg") ;;
            esac
          done
          command git "''${args[@]}"
        else
          command git "$@"
        fi
      }
    '';
  };
}
