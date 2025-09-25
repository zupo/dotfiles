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
    nixfmt-rfc-style
    deadnix
    statix
    pre-commit
    gitMinimal
    gawk
  ];

  shellHook = ''
    # Generate pre-commit config
    cat > .pre-commit-config.yaml << 'EOF'
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

    # Install pre-commit hooks
    pre-commit install --install-hooks
    pre-commit install --hook-type pre-push
  '';
}
