{
  pkgsUnstable,
  mcp-nixos,
  pkgs,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = pkgsUnstable.claude-code;

    # Commands are stored as markdown files in the claude/ directory
    commandsDir = ../claude;

    # MCP servers configuration
    mcpServers = {
      mcp-nixos = {
        command = "${mcp-nixos.packages.${pkgs.system}.default}/bin/mcp-nixos";
      };
    };
  };

  # Additional AI tools
  home.packages = [
    pkgsUnstable.codex
  ];
}
