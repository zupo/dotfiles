{
  pkgsUnstable,
  mcp-nixos,
  claude-plugins,
  pkgs,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = pkgsUnstable.claude-code;

    # Commands are stored as markdown files in the claude/ directory
    commandsDir = ../claude;

    # Code-simplifier agent from official plugins
    agentsDir = "${claude-plugins}/plugins/code-simplifier/agents";

    # MCP servers configuration
    mcpServers = {
      mcp-nixos = {
        command = "${mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/mcp-nixos";
      };
    };
  };

  # Additional AI tools
  home.packages = [
    pkgsUnstable.codex
  ];
}
