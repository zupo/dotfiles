# .files

These are my dotfiles. Take anything you want, but at your own risk.

It targets macOS systems, but it should work on \*nix as well.


## Install

```
$ git clone https://github.com/zupo/dotfiles.git ~/.dotfiles
$ ln -sv ~/.dotfiles/.bash_profile ~/
$ ln -sv ~/.dotfiles/.zshrc ~/
$ ln -sv ~/.dotfiles/.hushlogin ~/
$ ln -sv ~/.dotfiles/.gitignore ~/
$ ln -sv ~/.dotfiles/.gitattributes ~/
$ ln -sv ~/.dotfiles/darwin-configuration.nix ~/.nixpkgs/darwin-configuration.nix
$ ln -sv ~/.dotfiles/.vimrc ~/.vimrc
$ mv ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User.bak
$ ln -sv ~/.dotfiles/sublime ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
```


## Additional resources

- [Getting started with dotfiles](https://medium.com/@webprolific/getting-started-with-dotfiles-43c3602fd789)
- [@webpro's dotfiles](https://github.com/webpro/dotfiles)
- [Dotfiles community](https://dotfiles.github.io).
- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)
