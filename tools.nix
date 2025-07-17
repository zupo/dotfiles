{ pkgs, pkgsUnstable, ... }:
{
  home.packages = with pkgs; [
    pkgsUnstable.claude-code
    pkgsUnstable.codex
    asciinema
    axel
    atuin
    bat
    cachix
    devenv
    gnumake
    gnupg
    hyperfine
    inetutils  # telnet
    jq
    mkcert
    ncdu
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
  ];
}