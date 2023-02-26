# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# ============ Alias definitions ============
if [ -f ~/.shell_aliases ]; then
    . ~/.shell_aliases
fi

# ============ Alias ONLY for bash ============
alias vb="vim ~/.bashrc"
alias cb="cat ~/.bashrc"
alias sb="source ~/.bashrc"

select-history() {
    # Write to command-line.
    READLINE_LINE="$(HISTTIMEFORMAT='' history | awk '{print $2}' | fzf --query "$READLINE_LINE")"
    # Move cursor to the right end of the command-line.
    READLINE_POINT=$#READLINE_LINE
}
# Assign Ctrl + R.
bind -x '"\C-r": select-history'
