{
  config,
  lib,
  pkgs,
  ...
}:
let
  skills = [
    "teleport-from-cruncher"
    "teleport-to-cruncher"
  ];
in
{
  home.packages = [ (pkgs.callPackage ./hopsesh.nix { }) ];

  home.file = lib.mkIf pkgs.stdenv.isDarwin (
    builtins.listToAttrs (
      lib.concatMap
        (
          root:
          [
            {
              name = "${root}/teleport.md";
              value.source = ./skills/teleport.md;
            }
          ]
          ++ map (name: {
            name = "${root}/${name}/SKILL.md";
            value.source = ./skills + "/${name}/SKILL.md";
          }) skills
        )
        [
          ".agents/skills"
          ".claude/skills"
        ]
    )
  );

  xdg.configFile."hopsesh/config.toml".source =
    (pkgs.formats.toml { }).generate "hopsesh-config.toml"
      {
        schema = 4;
        repos_dir = "${config.home.homeDirectory}/work";
        layout = "flat";
        original = "off";
        sync_code = false;
        update_check = "off";
        peer.receive = !pkgs.stdenv.isDarwin;
        hosts =
          map
            (name: {
              inherit name;
              destination = name;
              allowed = true;
              via = "manual";
            })
            [
              "cruncher"
            ];
      };
}
