# Path to your oh-my-zsh installation.
export ZSH="/Users/zupo/.oh-my-zsh"

# Use the default theme that comes with oh-my-zsh
ZSH_THEME="robbyrussell"

# Enable a few neat features
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"


# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git sublime)

source $ZSH/oh-my-zsh.sh


# Better shell history
# (Inspired by https://scriptingosx.com/2019/06/moving-to-zsh-part-3-shell-options/)

# By default, when you exit zsh this particular instance of zsh
# will overwrite an existing history file with its history. So
# when you have multiple tabs open, they will all overwrite
# each others’ histories eventually. Tell zsh to use a single,
# shared history file across the sessions and append to it
# rather than overwrite:
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Tell zsh to update the history file after every command,
# rather than waiting for the shell to exit:
setopt INC_APPEND_HISTORY


# User configuration

export EDITOR="subl -w"
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export PATH=$PATH:$HOME/bin

# Disable generation of .pyc files
# https://docs.python-guide.org/writing/gotchas/#disabling-bytecode-pyc-files
export PYTHONDONTWRITEBYTECODE=0


# Aliases

# Preventing "whoops" moments
alias rm="trash"

# Show alternative progress bar for Axel downloader
alias axel="axel -a"

# Use video title as filename
alias youtube-dl="youtube-dl -t"

# Download a song from youtube
alias youtube-dl-audio="youtube-dl -i --extract-audio --audio-format mp3"

# rsync sane defaults
alias rsync="rsync -avzhP"

# force strong passwords
alias pwgen="pwgen --ambiguous 20"


# Better alternatives of common CLI commands
# (Inspired by https://remysharp.com/2018/08/23/cli-improved)
#
# Escape hatch: use `\`
# \cat # ignore aliases named "cat"
alias cat="bat"
alias ping="prettyping --nolegend"
alias diff="diff-so-fancy"
alias man="tldr"


# Change /etc/hosts and flush DNS cache
function edithosts {
    sudo vim /etc/hosts && echo "* Successfully edited /etc/hosts"
    sudo dscacheutil -flushcache && echo "* Flushed local DNS cache"
}


# Nix & direnv support
eval "$(direnv hook zsh)"
