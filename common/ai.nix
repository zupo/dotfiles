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

    # Code-simplifier agent from official plugins
    agentsDir = "${claude-plugins}/plugins/code-simplifier/agents";

    # Get team MCPs from teamniteo/claude
    mcpServers = niteo-claude.lib.mcpServers pkgs // {

      # Personal MCPs can be added here
      clinical-trials = {
        type = "http";
        url = "https://mcp.deepsense.ai/clinical_trials/mcp";
      };

    };

    # Get team Plugins from teamniteo/claude
    settings = {
      enabledPlugins = niteo-claude.lib.enabledPlugins // {

        # Personal plugins can be added here
        "ralph-loop@claude-plugins-official" = true;
      };
    };

    # Personal CLAUDE.md content
    memory.text = ''
      ## About the User

      Neyts Zupan (zupo) - Founder and CTO of Niteo.co, a bootstrapped multi-product company founded in 2006. Also founder of ParetoSecurity.com (macOS/iOS security app) and OceanSprint.org (developer sprints).

      **Location:** Slovenia, but winters on Lanzarote (Canary Islands) for windsurfing.

      **Technical preferences:**
      - Primary: Python, backend web development, DevOps
      - Functional programming enthusiast: Nix, Elm, Swift
      - Passionate about code quality, testing (pytest), and continuous delivery
      - Prefers NixOS/nix-darwin for reproducible environments

      **Work philosophy:**
      - Bootstrapped, not VC-funded - sustainable recurring revenue over growth-at-all-costs
      - Effectiveness over productivity - focus on impact, not hours
      - Open source advocate - believes in transparency and community

      **Personality:**
      - Geek since childhood, started coding in primary school
      - Active in open source communities (Plone, Python, Nix)
      - Organizes and attends tech conferences (PyCon, NixCon, sprints)
      - Values work-life balance - surfs, travels, family time

      **GitHub:** github.com/zupo - use the GitHub MCP to access private repos when needed.
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
