# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/kokoichi/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git autojump web-search fzf zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

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
# alias vi="nvim"
# alias vim="nvim"
# alias view="nvim -R"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# Android Studio
export PATH=$PATH:/Users/kokoichi/Library/Android/sdk/platform-tools


export PATH="$PATH:$(npm bin -g)"

export PATH="$PATH:/Users/kokoichi/flutter/bin"

export PATH="$PATH:/usr/local/go/bin/go"
export PATH="$PATH:$HOME/go/bin"
export GOPATH="$HOME/go"

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/Cellar/tfenv/2.2.3/versions/1.2.2/terraform terraform

alias gtt="/Users/kokoichi/ghq/github.com/kokoichi206/go-gtt/gtt"

source $HOME/.zshenv

export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"

export PATH="/opt/homebrew/opt/postgresql@12/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/postgresql@12/lib"
export CPPFLAGS="-I/opt/homebrew/opt/postgresql@12/include"

# ============ Alias definitions ============
if [ -f ~/.shell_aliases ]; then
    . ~/.shell_aliases
fi

# ============ Alias ONLY for zsh ============
alias sz="source ~/.zshrc"
alias cz="cat ~/.zshrc"
alias vz="vim ~/.zshrc"

# ============ Alias in my mac ============
alias koko="cd ~/ghq/github.com/kokoichi206/"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$PATH:$(go env GOPATH)/bin"


javahome() {
  unset JAVA_HOME 
  export JAVA_HOME=$(/usr/libexec/java_home -v "$1");
  java -version
}

alias j1.8='javahome 1.8'
alias j11='javahome 11'
alias j17='javahome 17'
j11

uuid() {
  uuidgen | tr A-Z a-z
}

. /opt/homebrew/opt/asdf/libexec/asdf.sh


export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# ======== k8s ========
alias kt='kubectl'
alias kc='kubectl'

# history of zsh
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
# NOT set this flag in order to keep past successful commands (and can be searched).
# setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY
setopt HIST_NO_STORE
setopt SHARE_HISTORY

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000

HISTORY_IGNORE="(vz|sz|cz|ls|cd|pwd|exit|cd ..|last_command=*|grep -vxF*|sed '$d' $HISTFILE*)"

precmd() {
    if [[ $? != 0 ]]; then
        # Write to $HISTFILE immediatlly.
        fc -W

        # Delete from $HISTFILE when the last command fails.
        # version1
        # last_command="$(tail -n1 $HISTFILE)";
        # grep -vxF "$last_command" $HISTFILE > temp_histfile && mv temp_histfile $HISTFILE
        # version2
        sed '$d' $HISTFILE > temp_histfile && mv temp_histfile $HISTFILE

        # NOT updating the history command here in order to load the previous command using the up arrow key.
        # fc -R $HISTFILE
    fi
}

select-history() {
    # Load from $HISTFILE (update history command).
    fc -R $HISTFILE

    # Write to command-line.
    # BUFFER="$(HISTCONTROL=ignoredups; history -n -r 1 | fzf --query "$BUFFER")"
    BUFFER="$(history | awk '{for(i=2;i<=NF;++i) printf "%s ", $i; printf "\n"}' | sort | uniq | fzf --query "$BUFFER")"

    # Move cursor to the right end of the command-line.
    CURSOR="$#BUFFER"
}
# Assign Ctrl + R.
zle -N select-history
bindkey '^r' select-history

alias ks='k9s'

export PATH="$HOME/.istio/istio-1.20.0/bin:$PATH"

nvm use 18.19.0

alias rr='echo $?'

export PATH="$HOME/.cargo/bin:$PATH"
