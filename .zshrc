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

# Hints taken from https://scriptingosx.com/2019/06/moving-to-zsh-part-3-shell-options/

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

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
