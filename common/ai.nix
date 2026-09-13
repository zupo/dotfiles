{
  niteo-claude,
  llm-agents,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:
{ config, ... }:
let
  agents = llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  peonSounds = pkgs.stdenvNoCC.mkDerivation {
    name = "peon-sounds";
    src = ../sounds;
    installPhase = ''
      mkdir -p $out
      cp *.ogg $out/
    '';
  };
  peonSoundHook = [
    {
      hooks = [
        {
          type = "command";
          command = "nohup afplay $(ls ${peonSounds}/*.ogg | sort -R | head -1) &>/dev/null &";
        }
      ];
    }
  ];

  # Mitigations for the idle-CPU/RSS bug (anthropics/claude-code#22509, #17148,
  # #19393, #86202 - all open). See SLOW.md for the full investigation.
  #
  # 2026-08-30: the BUN_JSC_* heap caps were REMOVED after they were measured
  # doing active harm. They capped the heap at 1.5GB while the live heap was
  # 11GB (peak 28GB on a `--resume` session), so JSC could never collect its
  # way under the cap and sat in permanent emergency GC: 5 `Heap Helper Thread`
  # at ~130% total, plus 8 `Bun Pool` threads at ~130% faulting the heap back
  # out of swap. A memory bug turned into a permanent CPU bug.
  #
  # They measured as harmless on 2026-08-24 only because the heap was 350-500MB
  # then - under the cap, so the cap was inert. The caps are safe right up until
  # they are not, which is why the earlier A/B could not see them.
  #
  # The mimalloc pair stays: the purge visibly returns pages (RSS oscillated
  # 2450 -> 1731 -> 1031MB under load). It has not been A/B'd on its own.
  #
  # The heap size itself is upstream's bug (#86202) and none of this fixes it.
  # The levers that actually work are `/clear` and not resuming multi-MB
  # transcripts.
  claudeTuned = pkgs.symlinkJoin {
    name = "claude-code-tuned";
    paths = [ agents.claude-code ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --set MIMALLOC_PURGE_DELAY 0 \
        --set MIMALLOC_ARENA_EAGER_COMMIT 0 \
        --set BUN_GC_TIMER_INTERVAL 300
    '';
  };

  # Shared by Claude Code (CLAUDE.md) and codex (AGENTS.md).
  personalContext = ''
    You are an expert engineer, hired to work alongside the user. You are
    also a fan of yugo-rock music and love to wiggle a funny phrase or
    a punchy verse into your answers when appropriate.

    Key overrides:
      - NEVER add Co-Authored-By footers to commits


    ## About the User

    Neyts Zupan (zupo) - Founder and CTO of Niteo.co, a bootstrapped multi-product company founded in 2007, based in EU. Also founder of
      * ParetoSecurity.com: macOS/linux security app and monitoring service
      * MayetRX: clinical trials vendor and project management software
      * OceanSprint.org: Nix(OS) developer hackathons

    - Passionate about code quality, testing, and continuous delivery.
    - Prefer unix-like tooling and command-line interfaces over GUIs and IDEs.
    - Bootstrapped, not VC-funded - sustainable recurring revenue over growth-at-all-costs.
    - Open source advocate - prefers contributing to and using open source software.
    - Effectiveness over productivity - focus on impact, not hours

    **GitHub:** github.com/zupo - use the `gh` CLI (already authenticated) to access private repos when needed.
    **Workstation:** github.com/zupo/dotfiles - usually invokes Claude from his nix-darwin-powered MacBook defined in these dotfiles.
  '';

  # Claude-only: codex has a hook system, but rtk ships no codex processor yet
  # (`rtk hook` knows claude/cursor/gemini/copilot/droid/vibe).
  rtkContext = ''


    ## RTK

    Bash calls are transparently rewritten through `rtk`, a proxy that
    compresses command output to save context. You do not need to invoke it
    yourself for ordinary commands - the hook handles it.

    - `rtk proxy <cmd>` - run a command UNFILTERED. Use this when you suspect
      the compression is hiding something you need (odd test output, a diff
      that looks truncated, a parse that doesn't add up).
    - `rtk gain` - token savings so far; `rtk discover` - missed opportunities.
    - Only Bash goes through rtk. `Read`, `Grep` and `Glob` are untouched.
  '';

  mcpServers = niteo-claude.lib.mcpServers pkgs // {

    # Personal MCPs can be added here
    clinical-trials = {
      type = "http";
      url = "https://mcp.deepsense.ai/clinical_trials/mcp";
    };

  };

  # Codex reads the same servers from config.toml, but with different keys and -
  # crucially - no `${VAR}` expansion anywhere. Translate mechanically:
  #   * `type` is dropped; codex infers stdio vs http from `command` / `url`
  #   * `headers` becomes `http_headers`
  #   * an env value that is a bare `${VAR}` becomes `env_vars`, codex's
  #     whitelist for forwarding a shell variable (i.e. one from .secrets.env)
  toCodexMcp =
    let
      placeholderVar =
        v:
        let
          m = if builtins.isString v then builtins.match "\\$\\{([A-Za-z_][A-Za-z_0-9]*)\\}" v else null;
        in
        if m == null then null else builtins.head m;

      convert =
        server:
        let
          env = server.env or { };
          forwarded = lib.filterAttrs (_: v: placeholderVar v != null) env;
          literal = builtins.removeAttrs env (builtins.attrNames forwarded);
        in
        builtins.removeAttrs server [
          "type"
          "env"
          "headers"
        ]
        // lib.optionalAttrs (literal != { }) { env = literal; }
        // lib.optionalAttrs (forwarded != { }) {
          env_vars = lib.mapAttrsToList (_: placeholderVar) forwarded;
        }
        // lib.optionalAttrs (server ? headers) { http_headers = server.headers; };
    in
    lib.mapAttrs (_: convert);

  # Sourcing .secrets.env directly, rather than trusting the spawned helper to
  # inherit the shell environment (codex scrubs some vars from child processes).
  prometheusAuthHelper = pkgs.writeShellScript "codex-prometheus-auth" ''
    . "${config.home.homeDirectory}/work/dotfiles/.secrets.env"
    printf '{"Authorization":"Basic %s"}' "$PROMETHEUS_AUTH"
  '';

  codexMcpServers =
    let
      translated = toCodexMcp mcpServers;
    in
    translated
    // {
      # `Basic ${PROMETHEUS_AUTH}` cannot survive that translation: codex never
      # expands headers, and `bearer_token_env_var` hardcodes a `Bearer` scheme.
      # `http_headers_helper` runs a command that prints the headers as JSON,
      # which lets us keep using the one PROMETHEUS_AUTH already in .secrets.env.
      prometheus = builtins.removeAttrs translated.prometheus [ "http_headers" ] // {
        http_headers_helper = toString prometheusAuthHelper;
      };
    };
in
{
  # Force max reasoning effort. The `effortLevel` setting is ignored on Opus
  # 4.7/4.8 — they ship a "launch-effort pin" that starts at `high` and only
  # clears when you touch `/effort` interactively. This env var is read first
  # and beats the pin (claude reads process.env.CLAUDE_CODE_EFFORT_LEVEL).
  home.sessionVariables.CLAUDE_CODE_EFFORT_LEVEL = "xhigh";

  programs.claude-code = {
    enable = true;
    package = claudeTuned;

    # Get team MCPs from teamniteo/claude, plus personal ones
    inherit mcpServers;

    settings = {
      # Prevent `Co-Authored-By: Claude` commit footer
      includeCoAuthoredBy = false;

      # Prevent auto-starting Remote Control
      remoteControlAtStartup = false;

      # Flicker-free alt-screen renderer with virtualized scrollback,
      # mouse support and auto-copy on select. Same as CLAUDE_CODE_NO_FLICKER=1.
      tui = "fullscreen";

      # The syntax highlighter runs Oniguruma over every visible block on every
      # render frame. Reported as the single biggest CPU win in #22509 (208% ->
      # ~50%), though it made no measurable difference here. See SLOW.md.
      # NOTE: because settings.json is a read-only /nix/store symlink, runtime
      # commands that persist settings (/tui, /model, theme) fail with EACCES.
      # Change them here, not in the TUI.
      syntaxHighlightingDisabled = true;

      # Play a random Warcraft peon sound when Claude is waiting for input
      hooks.Stop = peonSoundHook;
      hooks.Notification = peonSoundHook;

      # Compress Bash output through rtk before it reaches the context window
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${pkgsUnstable.rtk}/bin/rtk hook claude";
            }
          ];
        }
      ];

      # Register extra plugin marketplaces
      extraKnownMarketplaces = {
        hakuto = {
          source = {
            source = "github";
            repo = "teamniteo/hakuto";
          };
        };
        anthropic-agent-skills = {
          source = {
            source = "github";
            repo = "anthropics/skills";
          };
        };
      };

      # Get team Plugins from teamniteo/claude
      enabledPlugins = niteo-claude.lib.enabledPlugins // {

        # Personal plugins can be added here
        "hakuto@hakuto" = true;
        "example-skills@anthropic-agent-skills" = true;

      };

      # Get team Permissions from teamniteo/claude
      permissions.allow = niteo-claude.lib.permissions.allow ++ [

        # Personal permissions can be added here
        "mcp__clinical-trials__*"

        # Allow read-only `gh` commands (replacement for github MCP)
        "Bash(gh auth status)"
        "Bash(gh browse*)"
        "Bash(gh issue list*)"
        "Bash(gh issue view*)"
        "Bash(gh pr checks*)"
        "Bash(gh pr diff*)"
        "Bash(gh pr list*)"
        "Bash(gh pr view*)"
        "Bash(gh release list*)"
        "Bash(gh release view*)"
        "Bash(gh repo view*)"
        "Bash(gh run list*)"
        "Bash(gh run view*)"
        "Bash(gh search*)"
        "Bash(gh api*)"

        # Auto-allow read-only commands in common directories
        "Read(~/work/*)"
        "Read(~/tmp/*)"
        "Bash(cat ~/work/*)"
        "Bash(cat /tmp/*)"
        "Bash(head ~/work/*)"
        "Bash(head /tmp/*)"
        "Bash(ls ~/work/*)"
        "Bash(ls /tmp/*)"
        "Bash(tail ~/work/*)"
        "Bash(tail /tmp/*)"
      ];
    };

    # Personal CLAUDE.md content
    context = personalContext + rtkContext;
  };

  programs.codex = {
    enable = true;
    package = agents.codex;

    settings = {
      mcp_servers = codexMcpServers;

      # config.toml is a read-only /nix/store symlink, so codex cannot persist
      # directory trust itself - it fails with "failed to persist config at
      # /nix/store/...". Declare the trusted roots here instead; a new checkout
      # needs a line here plus a `nixre` before codex will work in it.
      projects =
        lib.genAttrs
          [
            "${config.home.homeDirectory}/work/dotfiles"
            "${config.home.homeDirectory}/work/servers"
          ]
          (_: {
            trust_level = "trusted";
          });
    };

    # Personal AGENTS.md content
    context = personalContext;
  };

  # Codex writes to config.toml at runtime - directory trust, `features enable`,
  # `/model` - which a read-only /nix/store symlink makes impossible. So Nix
  # generates the content and activation installs it as a real file, carrying
  # codex's own `[projects]` trust entries across rebuilds. Trust is an exact
  # path match: no globs, no inheritance from a parent directory, so codex has
  # to be able to record each repo itself.
  home.file.".codex/config.toml".enable = false;

  home.activation.codexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.python3}/bin/python3 ${./codex-config-merge.py} \
      ${config.home.file.".codex/config.toml".source} \
      ${config.home.homeDirectory}/.codex/config.toml
  '';

}
