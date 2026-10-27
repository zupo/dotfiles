{
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

  # Shared by Claude Code (CLAUDE.md) and codex (AGENTS.md).
  personalContext = ''
    You are an expert engineer, hired to work alongside the user.

    Key overrides:
      - NEVER add Co-Authored-By footers to commits
      - NEVER repeat the PR title in the PR body. Start the body with the description, across all projects.


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

  # Shared by Claude Code and codex: both run `rtk hook <agent>` as a
  # PreToolUse hook on shell commands.
  rtkContext = ''
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
  '';

  # Claude-only. Codex has "/fast" mode enabled.
  speedContext = ''
    ## Speed

    Time matters here: do not spend time that can be avoided, and the earlier
    a correct result is obtained, the better.
  '';

  mcpServers = niteo-agents.lib.mcpServers pkgs // {

    # Personal MCPs can be added here
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
      # Slack's OAuth client is registered for Claude Code's callback, and
      # Slack ships no codex client (its codex plugin declares no MCP servers).
      translated = toCodexMcp (builtins.removeAttrs mcpServers [ "slack" ]);
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
  # Pin reasoning effort to high. The `effortLevel` setting is ignored on Opus
  # 4.7/4.8 — they ship a "launch-effort pin" that starts at `high` and only
  # clears when you touch `/effort` interactively. This env var is read first
  # and beats the pin (claude reads process.env.CLAUDE_CODE_EFFORT_LEVEL).
  home.sessionVariables.CLAUDE_CODE_EFFORT_LEVEL = "high";

  programs.claude-code = {
    enable = true;
    package = agents.claude-code;

    # Get team MCPs from teamniteo/agents, plus personal ones
    inherit mcpServers;

    settings = {
      # Prevent `Co-Authored-By: Claude` commit footer
      includeCoAuthoredBy = false;

      # Prevent auto-starting Remote Control
      remoteControlAtStartup = false;

      # Start every session on Fable. The bare alias tracks the newest Fable
      # release (5.1 today), so it follows llm-agents bumps without editing.
      model = "fable";

      # Fullscreen renderer: alternate-screen drawing with in-app scrolling,
      # mouse support, copy on select and the /diff side panel.
      tui = "fullscreen";

      # NOTE: settings.json is a read-only /nix/store symlink, so runtime
      # commands that persist settings (/tui, /model, /effort, theme) fail with
      # EACCES. Change them here, not in the TUI.

      hooks = {
        # Compress Bash output through rtk before it reaches the context window
        PreToolUse = [
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

      # Get team Plugins from teamniteo/agents
      enabledPlugins = niteo-agents.lib.enabledPlugins // {

        # Personal plugins can be added here
        "hakuto@hakuto" = true;
        "example-skills@anthropic-agent-skills" = true;

      };

      # Get team Permissions from teamniteo/agents
      permissions.allow = niteo-agents.lib.permissions.allow ++ [

        # Personal permissions can be added here
        "mcp__clinical-trials__*"

        # Read-only Slack tools; sending, drafting and reacting still prompt.
        # home-manager serves its MCPs as a plugin, hence the prefix.
        "mcp__plugin_claude-code-home-manager_slack__slack_search_messages"
        "mcp__plugin_claude-code-home-manager_slack__slack_search_users"
        "mcp__plugin_claude-code-home-manager_slack__slack_search_channels"
        "mcp__plugin_claude-code-home-manager_slack__slack_list_user_channels"
        "mcp__plugin_claude-code-home-manager_slack__slack_read_channel"
        "mcp__plugin_claude-code-home-manager_slack__slack_read_thread"
        "mcp__plugin_claude-code-home-manager_slack__slack_read_canvas"
        "mcp__plugin_claude-code-home-manager_slack__slack_read_file"
        "mcp__plugin_claude-code-home-manager_slack__slack_fetch_user_info"

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
    context = personalContext + rtkContext + speedContext;
  };

  programs.codex = {
    enable = true;
    package = agents.codex;

    settings = {
      model = "gpt-6-astra";
      model_reasoning_effort = "medium";
      # Fast mode: `fast` maps to the `priority` service tier (2.5x subscription
      # usage). The `features.fast_mode` flag it needs is on by default.
      service_tier = "fast";

      # rtk records command history in its own SQLite store, which lives
      # outside the workspace. Without this the hook still rewrites commands
      # but every one of them fails to record (SQLITE_CANTOPEN).
      sandbox_workspace_write.writable_roots = [
        "${config.home.homeDirectory}/Library/Application Support/rtk"
      ];

      # Compress shell output through rtk before it reaches the context window.
      # Declared inline here rather than in hooks.json so that the trust codex
      # records for it (`[hooks.state.*]`, written to this same file) lives in
      # one place. Codex skips new or changed hooks until trusted with `/hooks`.
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${pkgsUnstable.rtk}/bin/rtk hook codex";
            }
          ];
        }
      ];

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
          [
            "${config.home.homeDirectory}/work/dotfiles"
            "${config.home.homeDirectory}/work/servers"
          ]
          (_: {
            trust_level = "trusted";
          });
    };

    # Personal AGENTS.md content
    context = personalContext + rtkContext;

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
