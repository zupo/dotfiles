# .files

These are my dotfiles. Take anything you want, but at your own risk.

They are used for configuring several of my environments:
 * MacBook with [nix-darwin](https://github.com/nix-darwin/nix-darwin),
 * NixOS VM running via [UTM](https://mac.getutm.app/) on the MacBook,
 * user account on a shared company NixOS server.


```
  ~/work/dotfiles/
  ├── flake.nix                   # Define all machines
  ├── flake.lock                  # Lock all dependencies
  │
  ├── common/                     # Shared modules across all systems
  │   ├── ai.nix
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
  ├── nixos/
  │   └── utm/                    # UTM VM
  │       ├── configuration.nix
  │       ├── hardware-configuration.nix
  │       └── home.nix
  │
  ├── .secrets.env                # Environment variables for secrets (git-ignored)
  ├── mkcert/                     # development certificates
  └── vscode/                     # VS Code settings
```

## Conventions

- Common modules go in `common/`, system-specific overrides in `darwin/` or `nixos/`
- Packages from unstable nixpkgs use `pkgsUnstable` (passed via `extraSpecialArgs`)
- Claude Code config is shared from `teamniteo/claude` repo via the `niteo-claude` flake input; personal overrides go in `common/ai.nix`
- No imperative changes — everything is declarative through Nix


## UTM NixOS VM setup

TODO...


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
