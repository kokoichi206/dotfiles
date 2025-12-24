# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

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
export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools


export PATH="$PATH:$(npm bin -g)"
export PATH="$(npm prefix -g)/bin:$PATH"

export PATH="$PATH:$HOME/flutter/bin"

export PATH="$PATH:/usr/local/go/bin/go"
export PATH="$PATH:$HOME/go/bin"
export GOPATH="$HOME/go"

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/Cellar/tfenv/2.2.3/versions/1.2.2/terraform terraform

alias gtt="$HOME/ghq/github.com/kokoichi206/go-gtt/gtt"

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

alias rr='echo $?'

export PATH="$HOME/.cargo/bin:$PATH"

jwt-claims () {
    awk -F. '(l = length($2)){printf $2} END {if (l%4 != 0) {for(i=1; i<=(4-l%4); i++){printf "="}}}' | base64 -d
}

jtg () {
	  node /usr/local/json-to-go/json-to-go.js
}
jtgc () {
	  pbpaste | jtg | pbcopy
}

alias tf='terraform'

alias pc='pbcopy'
alias date-now='TZ=Asia/Tokyo date +%Y%m%d_%H%M%S'

# Created by `pipx` on 2024-11-16 17:47:35
export PATH="$PATH:$HOME/.local/bin"


# asdf で ruby を install, build するため
export LDFLAGS="-L/opt/homebrew/opt/libffi/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libffi/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)"

export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# Added by Windsurf
export PATH="/Users/kokoichi206/.codeium/windsurf/bin:$PATH"

alias ws="windsurf"

# Added by Windsurf - Next
export PATH="/Users/kokoichi206/.codeium/windsurf/bin:$PATH"

alias gw="git worktree"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"



# iTerm2環境かどうかをチェック
is_iterm2() {
    [[ "$TERM_PROGRAM" == "iTerm.app" ]] || [[ -n "$ITERM_SESSION_ID" ]]
}

# iTerm2 Badge更新関数
update_iterm2_badge() {
    # iTerm2環境でない場合は何もしない
    if ! is_iterm2; then
        return
    fi

    local current_path="$PWD"
    local badge_text=""

    # ghq配下のパスかチェック
    if [[ "$current_path" =~ ^/Users/kokoichi206/ghq/github\.com/([^/]+)/([^/]+)/git/(.+)$ ]]; then
        # パターンマッチした場合
        local owner="${match[1]}"
        local repo="${match[2]}"
        local subpath="${match[3]}"
        badge_text="[$repo] $subpath"
    elif [[ "$current_path" =~ ^/Users/kokoichi206/ghq/ ]]; then
        # ghq配下だが上記のパターンにマッチしない場合
        badge_text="[ghq] ${current_path#/Users/kokoichi206/ghq/}"
    else
        # ghq配下でない場合は空にする（または好きな文字列に）
        badge_text=""
    fi

    # iTerm2のBadgeを設定
    printf "\033]1337;SetBadgeFormat=%s\007" "$(echo -n "$badge_text" | base64)"
}

# 既存のcustom_cdがある場合の対処
if type custom_cd > /dev/null 2>&1; then
    # 既存のcustom_cdを保存
    eval "original_$(declare -f custom_cd)"

    # 新しいcustom_cdを定義
    custom_cd() {
        # 元のcustom_cdを実行
        original_custom_cd "$@"
        # Badge更新
        update_iterm2_badge
    }
else
    # custom_cdが存在しない場合は新規作成
    custom_cd() {
        builtin cd "$@" && update_iterm2_badge
    }

    # cdをcustom_cdにエイリアス
    alias cd='custom_cd'
fi

# pushd/popdでも更新
pushd() {
    builtin pushd "$@" && update_iterm2_badge
}

popd() {
    builtin popd "$@" && update_iterm2_badge
}

update_iterm2_badge


# clacommand claudecommand claudeude() {
#     # 既存のclaudeコマンドを実行
#     command claude "$@"
#     # Badge更新
#     update_iterm2_badge
# }

export PATH="/opt/homebrew/opt/pueue/bin/pueue:$PATH"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# bun completions
[ -s "/Users/kokoichi206/.bun/_bun" ] && source "/Users/kokoichi206/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"



# =============================================================================
#
# Utility functions for zoxide.
#

# pwd based on the value of _ZO_RESOLVE_SYMLINKS.
function __zoxide_pwd() {
    \builtin pwd -L
}

# cd + custom logic based on the value of _ZO_ECHO.
function __zoxide_cd() {
    # shellcheck disable=SC2164
    \builtin cd -- "$@"
}

# =============================================================================
#
# Hook configuration for zoxide.
#

# Hook to add new entries to the database.
function __zoxide_hook() {
    # shellcheck disable=SC2312
    \command zoxide add -- "$(__zoxide_pwd)"
}

# Initialize hook.
\builtin typeset -ga precmd_functions
\builtin typeset -ga chpwd_functions
# shellcheck disable=SC2034,SC2296
precmd_functions=("${(@)precmd_functions:#__zoxide_hook}")
# shellcheck disable=SC2034,SC2296
chpwd_functions=("${(@)chpwd_functions:#__zoxide_hook}")
chpwd_functions+=(__zoxide_hook)

# Report common issues.
function __zoxide_doctor() {
    [[ ${_ZO_DOCTOR:-1} -ne 0 ]] || return 0
    [[ ${chpwd_functions[(Ie)__zoxide_hook]:-} -eq 0 ]] || return 0

    _ZO_DOCTOR=0
    \builtin printf '%s\n' \
        'zoxide: detected a possible configuration issue.' \
        'Please ensure that zoxide is initialized right at the end of your shell configuration file (usually ~/.zshrc).' \
        '' \
        'If the issue persists, consider filing an issue at:' \
        'https://github.com/ajeetdsouza/zoxide/issues' \
        '' \
        'Disable this message by setting _ZO_DOCTOR=0.' \
        '' >&2
    }

# =============================================================================
#
# When using zoxide with --no-cmd, alias these internal functions as desired.
#

# Jump to a directory using only keywords.
function __zoxide_z() {
    __zoxide_doctor
    if [[ "$#" -eq 0 ]]; then
        __zoxide_cd ~
    elif [[ "$#" -eq 1 ]] && { [[ -d "$1" ]] || [[ "$1" = '-' ]] || [[ "$1" =~ ^[-+][0-9]$ ]]; }; then
        __zoxide_cd "$1"
    elif [[ "$#" -eq 2 ]] && [[ "$1" = "--" ]]; then
        __zoxide_cd "$2"
    else
        \builtin local result
        # shellcheck disable=SC2312
        result="$(\command zoxide query --exclude "$(__zoxide_pwd)" -- "$@")" && __zoxide_cd "${result}"
    fi
}

# Jump to a directory using interactive search.
function __zoxide_zi() {
    __zoxide_doctor
    \builtin local result
    result="$(\command zoxide query --interactive -- "$@")" && __zoxide_cd "${result}"
}

# =============================================================================
#
# Commands for zoxide. Disable these using --no-cmd.
#

function z() {
    __zoxide_z "$@"
}

function zi() {
    __zoxide_zi "$@"
}

# Completions.
if [[ -o zle ]]; then
    __zoxide_result=''

    function __zoxide_z_complete() {
        # Only show completions when the cursor is at the end of the line.
        # shellcheck disable=SC2154
        [[ "${#words[@]}" -eq "${CURRENT}" ]] || return 0

            if [[ "${#words[@]}" -eq 2 ]]; then
                # Show completions for local directories.
                _cd -/

            elif [[ "${words[-1]}" == '' ]]; then
                # Show completions for Space-Tab.
                # shellcheck disable=SC2086
                __zoxide_result="$(\command zoxide query --exclude "$(__zoxide_pwd || \builtin true)" --interactive -- ${words[2,-1]})" || __zoxide_result=''

                # Set a result to ensure completion doesn't re-run
                compadd -Q ""

                # Bind '\e[0n' to helper function.
                \builtin bindkey '\e[0n' '__zoxide_z_complete_helper'
                # Sends query device status code, which results in a '\e[0n' being sent to console input.
                \builtin printf '\e[5n'

                # Report that the completion was successful, so that we don't fall back
                # to another completion function.
                return 0
            fi
        }

    function __zoxide_z_complete_helper() {
        if [[ -n "${__zoxide_result}" ]]; then
            # shellcheck disable=SC2034,SC2296
            BUFFER="z ${(q-)__zoxide_result}"
            __zoxide_result=''
            \builtin zle reset-prompt
            \builtin zle accept-line
        else
            \builtin zle reset-prompt
        fi
    }
\builtin zle -N __zoxide_z_complete_helper

[[ "${+functions[compdef]}" -ne 0 ]] && \compdef __zoxide_z_complete z
fi


# Added by Antigravity
export PATH="/Users/kokoichi206/.antigravity/antigravity/bin:$PATH"

# Added by Antigravity
export PATH="/Users/kokoichi206/.antigravity/antigravity/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/kokoichi206/Library/pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
eval "$(mise activate zsh)"


alias ei="eza --icons --git"
alias ea="eza -la --icons --git"
alias ee="eza -aahl --icons --git"
alias et="eza -T -L 3 -a -I 'node_modules|.git|.cache' --icons"
alias ls=ei
alias la=ea
alias ll=ee

# 既存 cd を置き換える。
eval "$(zoxide init zsh --cmd cd)"

alias gui='gitui'
alias vi='nvim'
alias vim='nvim'
