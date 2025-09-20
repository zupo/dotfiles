{ email, ... }:
{
  programs.git = {
    enable = true;
    diff-so-fancy.enable = true;
    userName = "Neyts Zupan";
    userEmail = email;
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

      # AI tooling
      "**/.claude/settings.local.json"
    ];
    extraConfig = {
      branch = {
        autosetuprebase = "always";
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
}
