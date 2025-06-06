# .files

These are my dotfiles. Take anything you want, but at your own risk.

It targets a macOS systems, but some of it should work on \*nix as well.


## Install

1. Use the official Nix installer for macOS: https://nixos.org/download.html#nix-install-macos

1. Follow `Flakes` install steps for nix-darwin: https://github.com/LnL7/nix-darwin

1. Another great resource is: https://nixcademy.com/2024/01/15/nix-on-macos/

1. Get my dotfiles and link them to places where they are used:

```
$ git clone https://github.com/zupo/dotfiles.git ~/.dotfiles
$ ln -sv ~/.dotfiles/vscode ~/Library/Application\ Support/Code/User
$ echo 'machine niteo.cachix.org password <CACHIX AUTH TOKEN>' >> ~/.config/nix/netrc
```

1. Create a `secrets.nix` file in your `.dotfiles` directory:

```nix
{
  email = "your.email@example.com";
  github = {
    token = "secret";
  };
}
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
* run `darwin-rebuild check --flake ~/.dotfiles#zbook`
* run `nixre`

## Troubleshooting

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
