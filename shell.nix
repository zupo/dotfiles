{
  system ? builtins.currentSystem,
}:

let
  flake = builtins.getFlake (toString ./.);
  inherit (flake.inputs) nixpkgs;
  pkgs = import nixpkgs { inherit system; };
in

pkgs.mkShell {
  buildInputs = with pkgs; [
    nixfmt
    deadnix
    statix
    prek
    gitMinimal
    gawk
  ];

  shellHook = ''
    # Generate prek config (prek reads pre-commit.com config format).
    # Always at the repo root, so entering the shell from a subdir does not
    # leave a stray config that prek would discover as a separate project.
    root=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
    cat > "$root/.pre-commit-config.yaml" << 'EOF'
    repos:
      - repo: local
        hooks:
          - id: nixfmt
            name: nixfmt
            entry: nixfmt
            language: system
            files: '\.nix$'
            pass_filenames: true

          - id: deadnix
            name: deadnix
            entry: deadnix --edit --no-lambda-pattern-names
            language: system
            files: '\.nix$'
            pass_filenames: true

          - id: statix
            name: statix
            entry: bash -c 'for file in "$@"; do statix fix "$file"; done' --
            language: system
            files: '\.nix$'
            pass_filenames: true
    EOF

    # Install git hooks
    prek install -f --hook-type pre-commit --hook-type pre-push
  '';
}
