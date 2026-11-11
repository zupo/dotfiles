{
  hakuto,
  passlet,
  niteo-agents,
  llm-agents,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:
{ config, ... }:
let
  agents = llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  personalContext = ''
    You are an expert engineer, hired to work alongside the user.

    Key overrides:
      - NEVER add Co-Authored-By footers to commits
      - NEVER repeat the PR title in the PR body. Start the body with the description, across all projects.
      - When Claude Code or Codex runs on my Mac, make dotfiles changes directly on `main` in `~/work/dotfiles` so I can immediately test them with `nixre`. This overrides the feature-branch and worktree rules for local dotfiles work. Preserve existing changes.


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

    **GitHub:** github.com/zupo
    **Workstation:** github.com/zupo/dotfiles - usually invokes Claude from his nix-darwin-powered MacBook defined in these dotfiles.

    ## RTK

    Bash calls are transparently rewritten through `rtk`, a proxy that
    compresses command output to save context. You do not need to invoke it
    yourself for ordinary commands - the hook handles it.

    - `rtk proxy <cmd>` - run a command UNFILTERED. Use this when you suspect
      the compression is hiding something you need (odd test output, a diff
      that looks truncated, a parse that doesn't add up).
    - `rtk gain` - token savings so far; `rtk discover` - missed opportunities.
    - Only shell commands go through rtk. File reads, edits and searches made
      through the agent's own tools are untouched.

    ## Speed

    Time matters here: do not spend time that can be avoided, and the earlier
    a correct result is obtained, the better.
  '';

  sharedContext =
    personalContext + niteo-agents.lib.rules.conventions + niteo-agents.lib.rules.tooling;

  plugins = {
    hakuto = hakuto.outPath;
    passlet = passlet.outPath;
  };

  rtkHooks = agent: [
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          command = "${pkgsUnstable.rtk}/bin/rtk hook ${agent}";
        }
      ];
    }
  ];

  # Personal MCPs can be added here
  personalMcpServers = {
    clinical-trials = {
      type = "http";
      url = "https://mcp.deepsense.ai/clinical_trials/mcp";
    };

    # Rex docs, changelog and Beta Discord history. Behind Discord OAuth (log in
    # with `/mcp`; needs Rex Beta Discord membership). Named `superlogical` as
    # the docs ask, to avoid clashing with Rex skills and the `rex` CLI.
    # https://www.superlogical.com/rex/docs/beta/community-mcp
    superlogical = {
      type = "http";
      url = "https://www.superlogical.com/rex/community-mcp";
    };

    # Slack's official server. It has no dynamic client registration, so the
    # OAuth client is the one Slack publishes for Claude Code in
    # github.com/slackapi/slack-mcp-plugin (.mcp.json). Log in with `/mcp`;
    # a workspace admin must allow the Claude app first.
    slack = {
      type = "http";
      url = "https://mcp.slack.com/mcp";
      oauth = {
        clientId = "1601185624273.8899143856786";
        callbackPort = 3118;
      };
    };

  };

  mcpServers = niteo-agents.lib.mcpServers pkgs // personalMcpServers;

  # Codex reads MCP servers with different keys and no `${VAR}` expansion;
  # teamniteo/agents translates its own servers and exports the translation.
  codexMcpServers =
    niteo-agents.lib.codexMcpServers pkgs {
      secretsFile = "${config.home.homeDirectory}/work/dotfiles/.secrets.env";
    }
    # Slack's OAuth client is registered for Claude Code's callback, and
    # Slack ships no codex client (its codex plugin declares no MCP servers).
    // niteo-agents.lib.toCodexMcp pkgs (builtins.removeAttrs personalMcpServers [ "slack" ]);
in
{
  # Pin reasoning effort to high. The `effortLevel` setting is ignored on Opus
  # 4.7/4.8 — they ship a "launch-effort pin" that starts at `high` and only
  # clears when you touch `/effort` interactively. This env var is read first
  # and beats the pin (claude reads process.env.CLAUDE_CODE_EFFORT_LEVEL).
  home.sessionVariables.CLAUDE_CODE_EFFORT_LEVEL = "high";

  home.file =
    lib.mapAttrs' (
      name: source:
      let
        manifest = builtins.fromJSON (
          builtins.readFile (
            if builtins.pathExists "${source}/plugin.json" then
              "${source}/plugin.json"
            else
              "${source}/.codex-plugin/plugin.json"
          )
        );
      in
      lib.nameValuePair ".codex/plugins/cache/${name}/${name}/${manifest.version}" {
        inherit source;
      }
    ) plugins
    // {
      ".codex/config.toml".enable = false;
    };

  programs.claude-code = {
    enable = true;
    package = agents.claude-code;
    plugins = builtins.attrValues plugins;

    # Get team MCPs from teamniteo/agents, plus personal ones
    inherit mcpServers;

    settings = {
      # Prevent `Co-Authored-By: Claude` commit footer
      includeCoAuthoredBy = false;

      # Prevent auto-starting Remote Control
      remoteControlAtStartup = false;

      model = "claude-fable-5-2";

      # passlet exec drops the Git config the sandbox injects for its proxy, but
      # keeps this variable, which Git reads for the same setting.
      env.GIT_HTTP_PROXY_AUTHMETHOD = "basic";

      permissions = {
        allow = [
          # An allow rule skips the auto-mode classifier, which refuses every
          # force push; GitHub's branch protection keeps main safe.
          "Bash(git push:*)"
          "Bash(rtk git push:*)"

          # A bare wildcard here is the documented way to open every host to
          # sandboxed commands: network.allowedDomains has no equivalent.
          "WebFetch(domain:*)"
        ];
        defaultMode = "auto";
      };
      sandbox = {
        enabled = true;
        # gh verifies TLS through the macOS trust service, which the sandbox
        # blocks by default. Its exfiltration risk is moot with the network open.
        enableWeakerNetworkIsolation = true;
        filesystem.allowWrite = [
          "${config.home.homeDirectory}/Library/Application Support/rtk"
        ];
        network.allowUnixSockets = [
          "${config.home.homeDirectory}/.local/share/passlet/passlet.sock"
          "${config.home.homeDirectory}/Library/Application Support/rex/server.sock"
        ];
      };

      # Fullscreen renderer: alternate-screen drawing with in-app scrolling,
      # mouse support, copy on select and the /diff side panel.
      tui = "fullscreen";

      # NOTE: settings.json is a read-only /nix/store symlink, so runtime
      # commands that persist settings (/tui, /model, /effort, theme) fail with
      # EACCES. Change them here, not in the TUI.

      hooks = {
        # Compress Bash output through rtk before it reaches the context window
        PreToolUse = rtkHooks "claude";

        # Rex's agent hook: tells Claude it runs inside Rex and in which
        # session/terminal. `rex skill setup` cannot write it here itself as
        # settings.json is a read-only store symlink, so it is declared by hand,
        # mirroring what Rex wrote to ~/.codex/hooks.json. `rex` is on PATH only
        # inside Rex terminals (REX_BIN_DIR, see darwin/zbook.nix); elsewhere
        # the `|| true` keeps the hook silent.
        # https://www.superlogical.com/rex/docs/automate/agent-skill
        SessionStart = [
          {
            hooks = [
              {
                type = "command";
                command = "/bin/sh -c 'rex __internal session-start --agent claude 2>/dev/null || true'";
                timeout = 5;
              }
            ];
          }
        ];
      };

      extraKnownMarketplaces.anthropic-agent-skills.source = {
        source = "github";
        repo = "anthropics/skills";
      };

      enabledPlugins = {
        "cc-plugin-you-should-know@builtin" = true;
        "example-skills@anthropic-agent-skills" = true;
      };
    };

    context = sharedContext;
  };

  programs.codex = {
    enable = true;
    package = agents.codex;

    settings = {
      marketplaces = lib.mapAttrs (_: source: {
        source_type = "local";
        inherit source;
      }) plugins;
      plugins = lib.mapAttrs' (name: _: lib.nameValuePair "${name}@${name}" { enabled = true; }) plugins;

      model = "gpt-6-astra";
      model_reasoning_effort = "medium";

      sandbox_workspace_write = {
        network_access = true;
        # rtk records command history in its own SQLite store, which lives
        # outside the workspace. Without this the hook still rewrites commands
        # but every one of them fails to record (SQLITE_CANTOPEN).
        writable_roots = [
          "${config.home.homeDirectory}/Library/Application Support/rtk"
        ];
      };

      # Compress shell output through rtk before it reaches the context window.
      # Declared inline here rather than in hooks.json so that the trust codex
      # records for it (`[hooks.state.*]`, written to this same file) lives in
      # one place. Codex skips new or changed hooks until trusted with `/hooks`.
      hooks.PreToolUse = rtkHooks "codex";

      sandbox_mode = "workspace-write";
      approval_policy = "on-request";
      approvals_reviewer = "auto_review";

      mcp_servers = codexMcpServers;

      # config.toml is a read-only /nix/store symlink, so codex cannot persist
      # directory trust itself - it fails with "failed to persist config at
      # /nix/store/...". Declare the trusted roots here instead; a new checkout
      # needs a line here plus a `nixre` before codex will work in it.
      projects =
        lib.genAttrs
          (map (name: "${config.home.homeDirectory}/work/${name}") [
            "agents"
            "canario"
            "dotfiles"
            "ebn"
            "ebn-nixos"
            "electronics"
            "gha-actions"
            "grafana"
            "handbook"
            "house"
            "mayet_ops"
            "oceansprint.org"
            "ops"
            "pareto-cloud"
            "pareto-linux"
            "pareto-mac"
            "passlet"
            "pyramid_jwt2"
            "pyramid_niteo"
            "pyramid_openapi3"
            "salarycalc"
            "scrooge"
            "servers"
            "site-hakuto"
            "site-mayetrx"
            "site-niteo"
            "site-paretosecurity"
            "site-passlet"
            "site-trialtrack"
            "socials"
            "trak"
            "vend"
            "wordformai"
          ])
          (_: {
            trust_level = "trusted";
          });
    };

    context = sharedContext;

  };

  # Codex writes to config.toml at runtime - directory trust, `features enable`,
  # `/model` - which a read-only /nix/store symlink makes impossible. So Nix
  # generates the content and activation installs it as a real file, carrying
  # codex's own `[projects]` trust entries across rebuilds. Trust is an exact
  # path match: no globs, no inheritance from a parent directory, so codex has
  # to be able to record each repo itself.
  home.activation.codexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.python3}/bin/python3 ${./codex-config-merge.py} \
      ${config.home.file.".codex/config.toml".source} \
      ${config.home.homeDirectory}/.codex/config.toml
  '';

}
