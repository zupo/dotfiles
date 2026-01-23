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

    # Merge Niteo MCPs with personal MCPs
    mcpServers = niteo-claude.lib.mcpServers pkgs // {
      # Personal MCPs can be added here
    };
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
