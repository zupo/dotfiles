let

  nixpkgs = builtins.fetchTarball {
    # https://github.com/NixOS/nixpkgs/tree/nixos-20.03 on 2020-04-29
    url = "https://github.com/nixos/nixpkgs/archive/ab3adfe1c769c22b6629e59ea0ef88ec8ee4563f.tar.gz";
    sha256 = "1m4wvrrcvif198ssqbdw897c8h84l0cy7q75lyfzdsz9khm1y2n1";
  };

  darwin = builtins.fetchTarball {
    # https://github.com/LnL7/nix-darwin/tree/master on 2020-04-29
    url = "https://github.com/LnL7/nix-darwin/archive/053f2cb9cb0ce7ceb4933cbd76e2d28713ad85da.tar.gz";
    sha256 = "04m9id1gzq0k7n5rkrds6y6r0mmhhsci3aqwhj3i691kx0sf09ia";
  };


in
  "nixpkgs=${nixpkgs}:darwin=${darwin}:darwin-config=/Users/zupo/.nixpkgs/darwin-configuration.nix"
