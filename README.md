# .files

These are my dotfiles. Take anything you want, but at your own risk.

It targets macOS systems, but it should work on \*nix as well.


## Install

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

# nix-channels are implicit and bad, so I don't use them but instead pin nixpkgs to commit hashes
# in pins/*.nix
$ rm ~/.nix-channels
$ rm ~/.nix-defexpr/channels

# what to do with /etc/zshrc and /etc/zprofile:
# https://github.com/LnL7/nix-darwin/issues/193
```


## Additional resources

- [Getting started with dotfiles](https://medium.com/@webprolific/getting-started-with-dotfiles-43c3602fd789)
- [@webpro's dotfiles](https://github.com/webpro/dotfiles)
- [Dotfiles community](https://dotfiles.github.io).
- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)
