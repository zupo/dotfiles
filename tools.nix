{ pkgs, pkgsUnstable, mcp-nixos, ... }:
{
  home.packages = with pkgs; [
    pkgsUnstable.claude-code
    pkgsUnstable.codex
    asciinema
    axel
    atuin
    bat
    cachix
    eza
    devenv
    gnumake
    gnupg
    hyperfine
    inetutils  # telnet
    jq
    mkcert
    ncdu
    neofetch
    ngrok
    nix-init
    nixd
    nixfmt-rfc-style
    nmap
    pdfcrack
    pgweb
    prettyping
    pwgen
    python3
    s3cmd
    tldr
    unrar
    wget

    # run `claude mcp add -s user mcp-nixos mcp-nixos` to enable it in Claude
    mcp-nixos.packages.${pkgs.system}.default
  ];
}