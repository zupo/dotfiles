# .files

These are my dotfiles. Take anything you want, but at your own risk.

It targets a macOS systems, but some of it should work on \*nix as well.


## Install

1. Use the official Nix installer for macOS: https://nixos.org/download.html#nix-install-macos

1. Follow `Install` steps for nix-darwin: https://github.com/LnL7/nix-darwin

1. Another great resource is: https://nixcademy.com/2024/01/15/nix-on-macos/

1. Get my dotfiles and link them to places where they are used:

```
$ git clone https://github.com/zupo/dotfiles.git ~/.dotfiles
$ ln -sv ~/.dotfiles/vscode ~/Library/Application\ Support/Code/User
```

1. `nix-channel`s are implicit and bad, so I remove them and instead use flakes to pin to exact nixpkgs commit hashes:

```
$ rm ~/.nix-channels
$ rm ~/.nix-defexpr/channels
```

1. What to do with `/etc/zshrc` and `/etc/zprofile`?


TL;DR:
```
$ sudo ln -sv ~/.dotfiles/zprofile.local /etc/zprofile.local
$ sudo ln -sv ~/.dotfiles/zshrc.local /etc/zshrc.local
```

## Details

MacOS comes with the following:

* `/etc/zprofile`
* `/etc/zshrc`
* `/etc/zshrc_Apple_Terminal`

I keep them in this repo, to track changes over time as new versions of macOS are released.

### `/etc/zprofile`

Saved in this repo as `zprofile.local` and symlinked into `/etc` where
nix-darwin generated `/etc/static/zprofile` loads it.

### `/etc/zshrc`

Saved in this repo as `zshrc.local` and symlinked into `/etc` where
nix-darwin generated `/etc/static/zshrc` loads it.

My personal ZSH configuration is in `~/.zshrc`.

### `/etc/zshrc_Apple_Terminal`

I don't use it because it only provides two features I don't need:
* emacs support,
* automatic history save/restore -> I prefer to use a shared history.

### Final result

In the end, the `/etc` folder should be like this:

```
/etc ➜ ls -l z
lrwxr-xr-x  1 root  wheel  20 Sep 14 18:17 zprofile -> /etc/static/zprofile
lrwxr-xr-x  1 root  wheel  36 Sep 20 13:42 zprofile.local -> /Users/zupo/.dotfiles/zprofile.local
lrwxr-xr-x  1 root  wheel  18 Apr  7  2020 zshenv -> /etc/static/zshenv
lrwxr-xr-x  1 root  wheel  17 Sep 20 11:30 zshrc -> /etc/static/zshrc
lrwxr-xr-x  1 root  wheel  33 Sep 20 13:27 zshrc.local -> /Users/zupo/.dotfiles/zshrc.local
```

Related: https://github.com/LnL7/nix-darwin/issues/193


## Additional resources

- [Getting started with dotfiles](https://medium.com/@webprolific/getting-started-with-dotfiles-43c3602fd789)
- [@webpro's dotfiles](https://github.com/webpro/dotfiles)
- [Dotfiles community](https://dotfiles.github.io).
- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)



nix-shell in direnv has broken prompt
/etc fajle je treba uredit
# (import (import /Users/zupo/.dotfiles/pins/nixpkgs_unstable.nix) {}).yt-dlp