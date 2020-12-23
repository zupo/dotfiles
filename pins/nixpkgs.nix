fetchTarball {
  # https://github.com/NixOS/nixpkgs/tree/nixos-unstable on 2020-12-09
  url = "https://github.com/nixos/nixpkgs/archive/e9158eca70ae59e73fae23be5d13d3fa0cfc78b4.tar.gz";
  sha256 = "0cnmvnvin9ixzl98fmlm3g17l6w95gifqfb3rfxs55c0wj2ddy53";
  # TODO: revert back to nixos-20.09 once fixes for building on Big Sur
  # have been backported -> building is needed for nmap 7.91
}
