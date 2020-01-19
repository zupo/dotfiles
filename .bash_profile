export EDITOR="subl -w"
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Add custom libs to PATH
home=/Users/$USER/bin
homebrew=/usr/local/bin:/usr/local/sbin
gems=/usr/local/opt/ruby/bin
PATH=$home:$gems:$homebrew:$PATH

# Based on: http://y-draw.com/blog/articles/2009/11/20/mac-os-x-terminal-configuration/
# colors for misc things
export TERM=xterm-color
export CLICOLOR=1
export LS_COLORS='di=1;36:fi=0:ln=4;34:pi=5:so=4;5:bd=5:cd=5:or=4;91:mi=4;92:ex=35:*.rb=90'
alias grep="grep --color=auto"

# Navigation aliases
alias ..="cd .."
alias ...="cd .. ; cd .."

# Preventing "whoops" moments
alias rm="trash" # always move to trash

# Show alternative progress bar for Axel downloader
alias axel="axel -a"

# Use video title as filename
alias youtube-dl="youtube-dl -t"

# Download a song from youtube
alias youtube-dl-audio="youtube-dl -i --extract-audio --audio-format mp3"

# rsync sane defaults
alias rsync="rsync -avzhP"

# Better alternatives of common CLI commands
# https://remysharp.com/2018/08/23/cli-improved
#
# Escape hatch: use `\`
# \cat # ignore aliases named "cat"
alias cat="bat"
alias ping="prettyping --nolegend"
alias diff="diff-so-fancy"
alias man='tldr'

# Because I like to have things in the same place
export PIPENV_VENV_IN_PROJECT=1

# Add pyenv pythons into path
eval "$(pyenv init -)"

# Automatic per-project loading of env vars via direnv.net
eval "$(direnv hook bash)"

# Disable generation of .pyc files
# https://docs.python-guide.org/writing/gotchas/#disabling-bytecode-pyc-files
export PYTHONDONTWRITEBYTECODE=0

# Change /etc/hosts and flush DNS cache
function edithosts {
    if [ -x "`which $EDITOR`" ] || [ -x "`which $1`" ]
    then
        if [ -x "`which $EDITOR`" ]
        then
            export TEMP_EDIT="`which $EDITOR`"
        else
            export TEMP_EDIT="`which $1`"
        fi
        sudo $TEMP_EDIT /etc/hosts && echo "* Successfully edited /etc/hosts"
        sudo dscacheutil -flushcache && echo "* Flushed local DNS cache"
    else
        echo "Usage: edithosts [editor]"
        echo "(The editor is optional, and defaults to \$EDITOR)"
    fi
    unset TEMP_EDIT
}

# git bash completion & git branch in prompt
if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi
if [ -f `brew --prefix`/etc/bash_completion.d/git-prompt.sh ]; then
    . `brew --prefix`/etc/bash_completion.d/git-prompt.sh
fi
export PS1="\W\$(__git_ps1)\$ "

# Load secrets
source ~/.dotfiles/.secrets

# Support for Nix
if [ -e /Users/zupo/.nix-profile/etc/profile.d/nix.sh ]; then . /Users/zupo/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
