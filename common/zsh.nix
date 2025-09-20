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
      rsync = "rsync -avzhP";
      pwgen = "pwgen --ambiguous 20";
      cat = "bat";
      ping = "prettyping --nolegend";
      diff = "diff-so-fancy";
      man = "tldr";
    };
    history = {
      append = true;
      share = true;
    };
    initContent = ''
      eval "$(atuin init zsh --disable-up-arrow)"
    '';
  };
}
