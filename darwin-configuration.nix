{ config, pkgs, ... }:

let
  inherit (pkgs) lorri;

in {
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 8;
  nix.buildCores = 8;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =[
    pkgs.axel
    pkgs.bat
    pkgs.direnv
    pkgs.gitAndTools.diff-so-fancy
    pkgs.lorri
    pkgs.ncdu
    pkgs.nmap
    pkgs.prettyping
    pkgs.pwgen
    pkgs.telnet
    pkgs.tldr
    pkgs.vim
    pkgs.wget
    pkgs.youtube-dl
  ];

  # Automatically start the lorri daemon
  launchd.user.agents = {
    "lorri" = {
      serviceConfig = {
        WorkingDirectory = (builtins.getEnv "HOME");
        EnvironmentVariables = { };
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/var/tmp/lorri.log";
        StandardErrorPath = "/var/tmp/lorri.log";
      };
      script = ''
        source ${config.system.build.setEnvironment}
        exec ${lorri}/bin/lorri daemon
      '';
    };
  };  


  # things I had installed with homebrew:
    # augeas
    # autoconf
    # awscli
    # axel
    # bash-completion
    # bash-git-prompt
    # bat
    # blueutil
    # cairo
    # circleci
    # cloc
    # composer
    # coreutils
    # dep
    # dialog
    # diff-so-fancy
    # direnv
    # elm-format
    # exiftool
    # faac
    # fcrackzip
    # fdk-aac
    # fontconfig
    # freetype
    # gd
    # gdbm
    # gettext
    # git
    # glib
    # go
    # gobject-introspection
    # gptfdisk
    # graphviz
    # gts
    # heroku
    # heroku-node
    # highlight
    # icu4c
    # ilmbase
    # imagemagick
    # jasper
    # jpeg
    # jq
    # keybase
    # lame
    # lftp
    # libav
    # libde265
    # libevent
    # libffi
    # libheif
    # libidn
    # libidn2
    # libmaxminddb
    # libogg
    # libomp
    # libpng
    # libpq
    # libssh
    # libtiff
    # libtool
    # libunistring
    # libvorbis
    # libvpx
    # libxml2
    # libyaml
    # libzip
    # little-cms2
    # lua
    # lynx
    # lz4
    # lzo
    # msgpack
    # ncdu
    # ncurses
    # netcat
    # netpbm
    # ngrok2
    # nmap
    # node
    # nspr
    # nss
    # nvm
    # oniguruma
    # openexr
    # openjpeg
    # openmotif
    # openssl
    # openssl@1.1
    # opus
    # pcre
    # pcre2
    # pgcli
    # pgweb
    # pixman
    # pkg-config
    # poetry
    # poppler
    # popt
    # prettyping
    # pwgen
    # python
    # qt
    # readline
    # ruby
    # s3cmd
    # sdl
    # shared-mime-info
    # shellcheck
    # sqlite
    # telnet
    # theora
    # tldr
    # tmate
    # tox
    # trash
    # tree
    # unrar
    # webp
    # wget
    # wine
    # x264
    # x265
    # xvid
    # xz
    # youtube-dl
    # zlib
}
