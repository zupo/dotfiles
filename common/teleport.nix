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
          map (name: {
            name = "${root}/${name}";
            # Codex skips a symlinked SKILL.md, and `..` from a linked directory resolves inside the Nix store.
            value.source = pkgs.runCommand name { } ''
              mkdir $out
              cp ${./skills + "/${name}/SKILL.md"} $out/SKILL.md
              cp ${./skills/teleport.md} $out/teleport.md
            '';
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
