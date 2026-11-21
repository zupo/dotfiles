{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  archives = {
    aarch64-darwin = {
      platform = "darwin_arm64";
      sha256 = "a9b38a38d5d46f28f399ea62d61297a3c44199abc3179224c7c0261b1630d8fd";
    };
    aarch64-linux = {
      platform = "linux_arm64";
      sha256 = "b54d56d3fd3f386a84b619c1e27e55846ea10beb83d0c24846d350d1e00f70db";
    };
    x86_64-darwin = {
      platform = "darwin_amd64";
      sha256 = "ea66b554143d8fc0bde64583adbd15e8be8b8bbe4e30d141cd92a2a630e9e8d2";
    };
    x86_64-linux = {
      platform = "linux_amd64";
      sha256 = "df81edd05c17fc2dad603eee6dae1805e9bc7e264bc1a50e0023834282a3da03";
    };
  };
  archive = archives.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation rec {
  pname = "hopsesh";
  version = "0.9.0";
  src = fetchurl {
    url = "https://github.com/roeehrl/hopsesh/releases/download/v${version}/hopsesh_${version}_${archive.platform}.tar.gz";
    inherit (archive) sha256;
  };
  sourceRoot = ".";
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 hopsesh "$out/bin/hopsesh"
    runHook postInstall
  '';
  meta = {
    description = "Move coding agent conversations between machines";
    homepage = "https://github.com/roeehrl/hopsesh";
    license = lib.licenses.asl20;
    mainProgram = "hopsesh";
    platforms = builtins.attrNames archives;
  };
}
