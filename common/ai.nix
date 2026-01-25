{
  pkgsUnstable,
  niteo-claude,
  claude-plugins,
  pkgs,
  lib,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = pkgsUnstable.claude-code;

    # Get team MCPs from teamniteo/claude
    mcpServers = niteo-claude.lib.mcpServers pkgs // {

      # Personal MCPs can be added here
      clinical-trials = {
        type = "http";
        url = "https://mcp.deepsense.ai/clinical_trials/mcp";
      };

    };

    settings = {

      # Get team Plugins from teamniteo/claude
      enabledPlugins = niteo-claude.lib.enabledPlugins // {

        # Personal plugins can be added here
        "ralph-loop@claude-plugins-official" = true;

      };

      # Get team Permissions from teamniteo/claude
      permissions.allow = niteo-claude.lib.permissions.allow ++ [

        # Personal permissions can be added here
        "mcp__clinical-trials__*"
      ];
    };

    # Personal CLAUDE.md content
    memory.text = ''
      ## About the User

      Neyts Zupan (zupo) - Founder and CTO of Niteo.co, a bootstrapped multi-product company founded in 2007, based in EU. Also founder of
        * ParetoSecurity.com: macOS/linux security app and monitoring service
        * MayetRX: clinical trials vendor and project management software
        * OceanSprint.org: Nix(OS) developer hackathons

      Work Philosophy:
        * Passionate about code quality, testing, and continuous delivery
        * Prefers simple, direct code over abstractions
        * Prefers unix-like tooling and command-line interfaces over GUIs and IDEs
        * Dislikes: unnecessary comments, over-engineering, unused code lying around
        * Bootstrapped, not VC-funded - sustainable recurring revenue over growth-at-all-costs
        * Effectiveness over productivity - focus on impact, not hours
        * Open source advocate - believes in transparency and community

      **GitHub:** github.com/zupo - use the GitHub MCP to access private repos when needed.
      **Workstation:** github.com/zupo/dotfiles - usually invokes Claude from his nix-darwin-powered MacBook defined in these dotfiles.
    '';
  };

  # Shared rules from Niteo (written to ~/.claude/rules/)
  # Convert this to programs.claude-code.rules when upgrading to 26.05
  home.file = lib.mapAttrs' (name: content: {
    name = ".claude/rules/${name}.md";
    value.text = content;
  }) niteo-claude.lib.rules;

  # Additional AI tools
  home.packages = [
    pkgsUnstable.codex
  ];
}
