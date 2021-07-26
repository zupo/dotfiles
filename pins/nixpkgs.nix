fetchTarball {
  # https://github.com/NixOS/nixpkgs/tree/nixos-unstable on 2020-12-09
  url = "https://github.com/nixos/nixpkgs/archive/84aa23742f6c72501f9cc209f29c438766f5352d.tar.gz";
  sha256 = "0h7xl6q0yjrbl9vm3h6lkxw692nm8bg3wy65gm95a2mivhrdjpxp";
  # TODO: revert back to nixos-20.09 once fixes for building on Big Sur
  # have been backported -> building is needed for nmap 7.91
}
