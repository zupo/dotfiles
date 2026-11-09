{
  pkgs,
  pkgsUnstable,
  ...
}:
{
  home.packages = with pkgs; [
    imapsync

    asciinema
    atuin
    axel
    bat
    cachix
    pkgsUnstable.devenv
    dig
    eza
    gh
    gnumake
    gnupg
    hyperfine
    jq
    lsd
    mkcert
    ncdu
    fastfetch
    ngrok
    nix-init
    nixd
    nixfmt
    nmap
    pdfcrack
    pgweb
    prettyping
    python3
    pwgen
    rclone
    pkgsUnstable.rtk
    s3cmd
    tldr
    unrar
    wget

    # Shadow Apple's /usr/bin/pip3 and /usr/bin/bundle, which are too old to
    # honor the release-age cooldowns set in files.nix.
    # Remove when Pareto Security 1.47 is released:
    # https://github.com/ParetoSecurity/pareto-mac/issues/352
    pkgsUnstable.python3Packages.pip
    ruby_4_0
  ];
}
