let

  nixpkgs = builtins.fetchTarball {
    # https://github.com/NixOS/nixpkgs/tree/nixos-20.03 on 2020-04-29
    url = "https://github.com/nixos/nixpkgs/archive/ab3adfe1c769c22b6629e59ea0ef88ec8ee4563f.tar.gz";
    sha256 = "1m4wvrrcvif198ssqbdw897c8h84l0cy7q75lyfzdsz9khm1y2n1";
  };

  darwin = builtins.fetchTarball {
    # https://github.com/LnL7/nix-darwin/tree/master on 2020-04-29
    url = "https://github.com/LnL7/nix-darwin/archive/ee2c31205c74da4862e22b33daea256b05856ee8.tar.gz";
    sha256 = "173zzc94phybzsqfsz5l7kq2m4p1wc0ic2qrryqi5j79lx3a9m2g";
  };


in
  "nixpkgs=${nixpkgs}:darwin=${darwin}:darwin-config=/Users/zupo/.nixpkgs/darwin-configuration.nix"
