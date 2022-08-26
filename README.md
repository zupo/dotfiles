# .files

These are my dotfiles. Take anything you want, but at your own risk.

It targets macOS systems, but it should work on \*nix as well.


## Install

1. Use the official Nix installer for macOS: https://nixos.org/download.html#nix-install-macos

2. Follow `Install` steps for nix-darwin: https://github.com/LnL7/nix-darwin

3. Get my dotfiles and link them to places where they are used:

```
$ git clone https://github.com/zupo/dotfiles.git ~/.dotfiles
$ ln -sv ~/.dotfiles/.zshrc ~/
$ ln -sv ~/.dotfiles/.hushlogin ~/
$ ln -sv ~/.dotfiles/.gitignore ~/
$ ln -sv ~/.dotfiles/.gitattributes ~/
$ ln -sv ~/.dotfiles/.vimrc ~/.vimrc
$ ln -sv ~/.dotfiles/.direnvrc ~/.direnvrc
$ ln -sv ~/.dotfiles/darwin-configuration.nix ~/.nixpkgs/darwin-configuration.nix
$ mv ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User.bak
$ ln -sv ~/.dotfiles/sublime ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User


4. `nix-channel`s are implicit and bad, so I remove them and instead pin nixpkgs to commit hashes in [`pins/*.nix`](https://github.com/zupo/dotfiles/tree/master/pins):

```
$ rm ~/.nix-channels
$ rm ~/.nix-defexpr/channels
```

5. Cleanup or what to do with /etc/zshrc and /etc/zprofile: https://github.com/LnL7/nix-darwin/issues/193


## Additional resources

- [Getting started with dotfiles](https://medium.com/@webprolific/getting-started-with-dotfiles-43c3602fd789)
- [@webpro's dotfiles](https://github.com/webpro/dotfiles)
- [Dotfiles community](https://dotfiles.github.io).
- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)
