# .files

These are my dotfiles. Take anything you want, but at your own risk.

They are used for configuring several of my environments:
 * MacBook with [nix-darwin](https://github.com/nix-darwin/nix-darwin),
 * user account on a shared company NixOS server.


```
  ~/work/dotfiles/
  ├── flake.nix                   # Define all machines
  ├── flake.lock                  # Lock all dependencies
  │
  ├── common/                     # Shared modules across all systems
  │   ├── ai.nix
  │   ├── codex-config-merge.py  # keeps codex's config.toml writable
  │   ├── direnv.nix
  │   ├── files.nix
  │   ├── gitconfig.nix
  │   ├── tools.nix
  │   ├── vim.nix
  │   └── zsh.nix
  │
  ├── darwin/
  │   ├── zbook.nix               # nix-darwin for my MacBook
  │   └── home.nix                # Home Manager for my MacBook
  │
  ├── .secrets.env                # Environment variables for secrets (git-ignored)
  ├── mkcert/                     # development certificates
  └── vscode/                     # VS Code settings
```

## Conventions

- Common modules go in `common/`, system-specific overrides in `darwin/`
- Packages from unstable nixpkgs use `pkgsUnstable` (passed via `extraSpecialArgs`)
- Claude Code config is shared from `teamniteo/agents` repo via the `niteo-agents` flake input; personal overrides go in `common/ai.nix`
- Codex is configured alongside Claude Code in `common/ai.nix`: it gets the same personal context (as `AGENTS.md`) and the same MCP servers, translated into codex's `config.toml` keys
- Codex needs a writable `config.toml` (directory trust, `features enable`, `/model`), so Nix generates it and an activation script installs a real file instead of a store symlink, carrying codex's own `[projects]` trust entries across rebuilds
- No imperative changes — everything is declarative through Nix


## MacBook setup

1. Use the official Nix installer for macOS: https://nixos.org/download.html#nix-install-macos

1. Follow `Flakes` install steps for nix-darwin: https://github.com/LnL7/nix-darwin

1. Another great resource is: https://nixcademy.com/2024/01/15/nix-on-macos/

1. Get my dotfiles and link them to places where they are used:

```
$ git clone https://github.com/zupo/dotfiles.git ~/work/dotfiles
$ ln -sv ~/work/dotfiles/vscode ~/Library/Application\ Support/Code/User
$ echo 'machine niteo.cachix.org password <CACHIX AUTH TOKEN>' >> ~/.config/nix/netrc
```

1. Create secret files in the `dotfiles` directory:

   `.secrets.env` for environment variables:
   ```bash
   export OPENAI_API_KEY="sk-proj-..."
   export CACHIX_AUTH_TOKEN="..."
   ```

1. `nix-channel`s are implicit and bad, so I remove them and instead use flakes to pin to exact nixpkgs commit hashes:

```
$ rm ~/.nix-channels
$ rm ~/.nix-defexpr/channels
$ rm ~/.nixpkgs/
```

1. The Nix installer also puts `nss-cacert` into the default profile. Nothing reads its CA bundle, since nix-darwin provides `/etc/ssl/certs/ca-certificates.crt` (honouring `security.pki.caCertificateBlacklist`), but it never gets updated, so it keeps trusting distrusted CAs and fails the [Pareto Security compromised CA check](https://paretosecurity.com/mac/checks/compromised-ca). Remove it:

```
$ sudo nix-env -p /nix/var/nix/profiles/default -e nss-cacert
```

1. What to do with `/etc/zshrc` and `/etc/zprofile`?

MacOS comes with the following:

* `/etc/zprofile`
* `/etc/zshrc`
* `/etc/zshrc_Apple_Terminal`

### `/etc/zprofile`

I don't use it because it only provides load `/usr/libexec/path_helper` which is slow and not needed.

Also, https://github.com/LnL7/nix-darwin/issues/532.

### `/etc/zshrc_Apple_Terminal`

I don't use it because it only provides two features I don't need:
* emacs support,
* automatic history save/restore -> I prefer to use a shared history.

### `/etc/zshrc`

I override this one with my personal settings using flake.nix

### Final result

In the end, the `/etc` folder should be like this:

```
/etc ➜ ls -l z*
lrwxr-xr-x  1 root  wheel  20 Sep 14 18:17 zprofile -> /etc/static/zprofile
lrwxr-xr-x  1 root  wheel  18 Apr  7  2020 zshenv -> /etc/static/zshenv
lrwxr-xr-x  1 root  wheel  17 Sep 20 11:30 zshrc -> /etc/static/zshrc
```

Related: https://github.com/LnL7/nix-darwin/issues/193


## Updating

### Agent instructions

Claude Code and Codex receive the same personal instructions, RTK guidance, speed preference, and general team rules from one shared context. Home Manager writes it to their required global files, `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`. Both use the same plugin source declarations and RTK hook definition. MCP servers share one source with a Codex format adapter; Slack remains Claude-only because its OAuth client uses Claude’s callback.

On zbook, the sessions for `dotfiles`, `socials`, and `support` occupy the first three positions when open. Their initial first tabs get those names and are exempt from task-based naming while first. Agents name all other tabs on zbook and every tab on cruncher after their task with `rex window rename`. Every session follows its current first tab, including the pinned sessions: moving or closing that tab changes the session name. Explicit tab names take precedence; autogenerated tab names use the focused terminal's title, stripped of leading Braille spinners and the trailing ` | zupo`.

A Home Manager LaunchAgent runs `common/rex-session-names.lua`, listening for title and layout changes across all local sessions. It recognizes the three pinned sessions by their named tabs when restarted, and initializes their first-tab names from their session names when needed. Launchd restarts the listener if it exits. Apply with `nixre`; errors go to `~/Library/Logs/rex-session-names.log`. Run the naming regression tests with `lua tests/rex-session-names.lua` from the repository root.

Inside Rex, both agents run long-running commands side by side in a single row occupying the top quarter of their current window, separated by vertical dividers. The main agent spans the full width of the bottom three quarters and retains focus. They verify the resulting layout, collect output and exit status, then close finished panes unless asked to keep them. Asked to open a project, they start a Rex session in `~/work/<project>` that pulls `main`, reloads direnv and starts Claude. Apply instruction changes with `nixre` and start new agent sessions.

On this Mac, agents work and commit locally on `main` in dotfiles and socials. They push to `main` only when explicitly asked. Implementing, testing or committing does not authorize a push. The same rule applies to `/etc/nixos` on cruncher. These repositories do not use feature branches, worktrees, or pull requests for agent changes.

### Agent plugins

Run `/teleport-to-cruncher` on zbook to push the current Claude Code conversation and working changes to cruncher, or `/teleport-from-cruncher` on zbook to select and pull a remote conversation back. Codex uses `$teleport-to-cruncher` and `$teleport-from-cruncher`. All SSH connections originate on the Mac; neither Remote Login nor inbound Rex access is needed. The shared `common/tools.nix` module installs the skills on macOS and pins [hopsesh](https://github.com/roeehrl/hopsesh) 0.9.0 on both hosts. Hopsesh runs on demand, with no background service. Only cruncher enables receiving.

The skills transfer Git history and staged, unstaged and untracked work separately, verify the destination, and resume the selected agent in Rex. A private transfer receipt distinguishes unchanged outgoing edits from conflicting local work on return. Credentials and running processes stay on their original host. After transfer, continue only in the destination tab and keep the source idle as a recovery copy.

Hopsesh may convert a conversation to portable history across machine profiles, even with matching Claude logins. That can omit reasoning or shorten older context. The skills inspect its loss report and ask before transferring a working conversation that way, preserving the original when exact history is required.

Apply with `nixre` on zbook and a dotfiles-pin update/rebuild on cruncher. Both hosts need their own agent login and Rex, and zbook needs outbound SSH access to cruncher. Hopsesh keeps separate SSH host-key records, so the first transfer may need fingerprint verification. Its configuration is Nix-managed, use neither its installer nor its self-updater. The workflow and research links are in [common/skills/teleport.md](common/skills/teleport.md).

Nix pins the plugin code in `flake.lock`. Claude Code loads Passlet and Hakuto directly from the Nix store through Home Manager's `plugins` option. The built-in Claude plugin follows the pinned Claude package. Claude-only example skills use Claude’s native plugin manager, with their marketplace and enabled state declared in Nix. Their code is not pinned in `flake.lock`.

Codex's Passlet and Hakuto marketplaces point to the same pinned Nix sources as Claude. Home Manager installs their versioned Codex cache entries as links to the Nix store, so installation, source, and enabled state are all declared in Nix. ChatGPT's account-managed plugins are separate from these repository plugins.

Update with `nix flake update hakuto passlet`, then run `nixre` and start new agent sessions. No plugin install or upgrade commands are needed for these shared plugins. Update Claude-only example skills through Claude’s plugin manager. Passlet's pin controls both the app package and its plugin source.

### Passlet remote access

The Mac's Home Manager configuration installs Passlet and enables `programs.passlet.service.tailscale`. When the Approver starts, it checks Tailscale Serve and configures missing HTTPS forwarding on port `17400` to its private Unix socket. Tailscale 1.104.4 or newer must already be running and signed in. Conflicting forwarding is rejected, and other Tailscale Serve ports are left unchanged.

The forwarding persists across restarts. Inspect it with `tailscale serve status` and check service health with `passlet approver doctor`. To disable remote access, set `programs.passlet.service.tailscale = false`, apply the configuration with `nixre`, and remove the persistent HTTPS forwarding with `tailscale serve --https=17400 off`.

### Updating inputs

To update to the latest release in the currently used channel, run
`nix flake update` followed by `nixre`.

When a new nixpkgs channel is released, do the following:
* update the `nixpkgs.url` input in `flake.nix` to the new channel
* run `nixre`

## Troubleshooting

### Debugging MCP Servers

MCP server logs are at `~/Library/Caches/claude-cli-nodejs/<project-path>/mcp-logs-<server-name>/` where `<project-path>` is the working directory with slashes replaced by dashes (e.g., `-Users-zupo--dotfiles`). Each directory contains `.jsonl` files with timestamped entries. Session debug logs are at `~/.claude/debug/` with a `latest` symlink.

### `Problem with the SSL CA cert (path? access rights?)`

If you see this error when trying to reinstall, follow https://discourse.nixos.org/t/ssl-ca-cert-error-on-macos/31171/5.

### `No space left on device`

If you see an error like this:

```console
> mkdir: cannot create directory '/nix/store/31k835115bylz5qb3k7vhcvfgrl4cwpl-nixos-disk-image/nix-support': No space left on device
```

The problem might not be with your macOS disk space, but with the nix-darwin's linux-builder disk space. Fix it like this:

```console
$ sudo ssh linux-builder
[builder@nixos:~]$ nix-collect-garbage
```


## Additional resources

- [Getting started with dotfiles](https://webpro.nl/articles/getting-started-with-dotfiles)
- [@webpro's dotfiles](https://github.com/webpro/dotfiles)
- [Dotfiles community](https://dotfiles.github.io).
- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)

Personal instructions live in `common/personal-context.md`, exported as `lib.personalContext` for the cruncher account. Zbook and cruncher use the same `common/rex-session-names.lua`, exported as `lib.rexSessionNames`. Server updates take effect after the weekly dotfiles pin update is merged and the server rebuild succeeds. Start new Claude Code and Codex sessions to load changed instructions.
