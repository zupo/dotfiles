_: {
  # Don't show the "Last login" message for every new terminal.
  home.file.".hushlogin" = {
    text = "";
  };

  # Supply-chain protection: refuse npm/Bun/PyPI packages younger than 7 days,
  # so freshly-published malicious versions get caught before we install.
  # pip key requires pip 26.0+; uv duration syntax requires uv 0.9.17+.
  home.file.".npmrc".text = ''
    min-release-age=7
    minimum-release-age=10080
    save-exact=true
  '';
  home.file.".bunfig.toml".text = ''
    [install]
    minimumReleaseAge = 604800
  '';
  home.file.".config/uv/uv.toml".text = ''
    exclude-newer = "7 days"
  '';
  home.file.".config/pip/pip.conf".text = ''
    [install]
    uploaded-prior-to = P7D
  '';
}
