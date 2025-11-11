{
  pkgs,
  pkgsUnstable,
  mcp-nixos,
  ...
}:
{
  home.packages = with pkgs; [
    pkgsUnstable.claude-code
    pkgsUnstable.codex
    asciinema
    atuin
    axel
    bat
    cachix
    pkgsUnstable.devenv
    dig
    eza
    gnumake
    gnupg
    hyperfine
    inetutils # telnet
    jq
    lsd
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
    python3
    pwgen
    rclone
    s3cmd
    tldr
    unrar
    wget

    # run `claude mcp add -s user mcp-nixos mcp-nixos` to enable it in Claude
    mcp-nixos.packages.${pkgs.system}.default
  ];
}
