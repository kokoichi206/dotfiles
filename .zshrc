# ============ Shell behavior ============
# 貼り付けた shell snippet のコメント行を対話シェルでも無視する
setopt INTERACTIVE_COMMENTS

# ============ Completion ============
autoload -Uz compinit
# compinit の再生成は1日1回に抑える
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
autoload -U +X bashcompinit && bashcompinit

# ============ Abbreviations (zsh-abbr) ============
# パイプや ; && || の後（コマンド位置）でも regular 略語を展開する。引数位置では展開しない。
# sheldon が zsh-abbr を読み込む前に設定する必要がある。
# https://github.com/olets/zsh-abbr/issues/53
export ABBR_EXPERIMENTAL_COMMAND_POSITION_REGULAR_ABBREVIATIONS=2

# ============ Sheldon (plugin manager) ============
eval "$(sheldon source)"

# ============ Default Editor ============
export EDITOR="nvim"

# ============ XDG Base Directory ============
export XDG_CONFIG_HOME="$HOME/.config"

# ============ Abbreviations ============
export ABBR_USER_ABBREVIATIONS_FILE="${XDG_CONFIG_HOME}/zsh-abbr/user-abbreviations"

# ============ PATH ============
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.istio/istio-1.20.0/bin:$PATH"
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
export PATH="$HOME/flutter/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export PATH="/opt/homebrew/opt/pueue/bin/pueue:$PATH"
export PATH="~/.codeium/windsurf/bin:$PATH"

export GOPATH="$HOME/go"

# pnpm
export PNPM_HOME="~/Library/pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ============ Environment ============
source $HOME/.zshenv

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# asdf/mise で ruby を build するため
export LDFLAGS="-L/opt/homebrew/opt/libffi/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libffi/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/opt/homebrew/opt/openssl@3"

# ============ Alias definitions ============
if [ -f ~/.shell_aliases ]; then
    . ~/.shell_aliases
fi

# ============ Word boundaries ============
# `/` を除外して `origin/main` のようなパスを Ctrl+W / Option+Delete で
# 一語ずつ消せるようにする。デフォルト値から差分だけを引く形で書く。
WORDCHARS=${WORDCHARS:s@/@}

# ============ History ============
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

# 失敗コマンドを履歴から削除
_remove_failed_command() {
    if [[ $? != 0 ]]; then
        fc -W
        sed '$d' $HISTFILE > temp_histfile && mv temp_histfile $HISTFILE
    fi
}
precmd_functions+=(_remove_failed_command)

select-history() {
    fc -R $HISTFILE
    BUFFER="$(history | awk '{for(i=2;i<=NF;++i) printf "%s ", $i; printf "\n"}' | sort | uniq | fzf --query "$BUFFER")"
    CURSOR="$#BUFFER"
}
zle -N select-history
bindkey '^r' select-history

# prefix history search:
# 何か入力した状態で ↑/↓ を押すと、その prefix で始まる履歴だけを遡る/進む。
# 空入力時は通常の history-up/down として動く。
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search    # ↑
bindkey '^[[B' down-line-or-beginning-search  # ↓

# ============ Custom functions ============
javahome() {
  unset JAVA_HOME
  export JAVA_HOME=$(/usr/libexec/java_home -v "$1");
  java -version
}

uuid() {
  uuidgen | tr A-Z a-z
}

jwt-claims () {
    awk -F. '(l = length($2)){printf $2} END {if (l%4 != 0) {for(i=1; i<=(4-l%4); i++){printf "="}}}' | base64 -d
}

jtg () {
    node /usr/local/json-to-go/json-to-go.js
}
jtgc () {
    pbpaste | jtg | pbcopy
}

kp() {
  if [[ -z "$1" ]]; then
    echo "Usage: kp <port>"
    return 1
  fi

  local pids
  pids=("${(@f)$(lsof -t -i :"$1")}")

  if (( ${#pids[@]} == 0 )); then
    echo "No process using port $1"
    return 0
  fi

  echo "Killing: ${pids[@]}"
  kill -9 "${pids[@]}"
}

# ============ iTerm2 Badge ============
is_iterm2() {
    [[ "$TERM_PROGRAM" == "iTerm.app" ]] || [[ -n "$ITERM_SESSION_ID" ]]
}

update_iterm2_badge() {
    if ! is_iterm2; then
        return
    fi

    local current_path="$PWD"
    local badge_text=""

    if [[ "$current_path" =~ ^/Users/kokoichi206/ghq/github\.com/([^/]+)/([^/]+)/git/(.+)$ ]]; then
        local owner="${match[1]}"
        local repo="${match[2]}"
        local subpath="${match[3]}"
        badge_text="[$repo] $subpath"
    elif [[ "$current_path" =~ ^/Users/kokoichi206/ghq/ ]]; then
        badge_text="[ghq] ${current_path#/Users/kokoichi206/ghq/}"
    else
        badge_text=""
    fi

    printf "\033]1337;SetBadgeFormat=%s\007" "$(echo -n "$badge_text" | base64)"
}

if type custom_cd > /dev/null 2>&1; then
    eval "original_$(declare -f custom_cd)"
    custom_cd() {
        original_custom_cd "$@"
        update_iterm2_badge
    }
else
    custom_cd() {
        builtin cd "$@" && update_iterm2_badge
    }
    alias cd='custom_cd'
fi

pushd() {
    builtin pushd "$@" && update_iterm2_badge
}

popd() {
    builtin popd "$@" && update_iterm2_badge
}

update_iterm2_badge

# ============ Tool initialization ============
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# direnv (nix-direnv) のフック
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

eval "$(mise activate zsh)"

# zoxide と starship は末尾で初期化（precmd hooks の順序のため）
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"

# WezTerm: OSC 7 で cwd を通知する。Pane Finder（leader+f）が各 pane の cwd を
# 正確に追跡するために必要。WezTerm 上でのみ有効化し、他端末には影響させない。
if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
  _wezterm_osc7() { printf '\033]7;file://%s%s\033\\' "${HOST}" "${PWD}" }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _wezterm_osc7
fi

# ============ Claude Code skill management ============
DOTFILES_DIR="$HOME/ghq/github.com/kokoichi206/dotfiles"

claude-skill-try() {
    local skill_name="$1"
    if [ -z "$skill_name" ]; then
        echo "Usage: claude-skill-try <skill-name>"
        echo "  Creates a temporary skill in ~/.claude/skills/ for testing"
        echo "  Use 'claude-skill-promote' to move it to dotfiles when ready"
        return 1
    fi

    local skill_dir="$HOME/.claude/skills/$skill_name"
    if [ -d "$skill_dir" ]; then
        echo "Skill already exists: $skill_dir"
        ${EDITOR:-vim} "$skill_dir/SKILL.md"
        return 0
    fi

    mkdir -p "$skill_dir"
    cat > "$skill_dir/SKILL.md" <<EOF
---
name: $skill_name
description:
---

# $skill_name

## 概要

## 主要原則

## チェックリスト

- [ ]
EOF

    echo "Created temporary skill: $skill_dir/SKILL.md"
    echo "Try it out, then run 'claude-skill-promote $skill_name' to add to dotfiles"
    ${EDITOR:-vim} "$skill_dir/SKILL.md"
}

claude-skill-promote() {
    local skill_name="$1"
    if [ -z "$skill_name" ]; then
        echo "Usage: claude-skill-promote <skill-name>"
        echo "  Moves skill from ~/.claude/skills/ to dotfiles and creates symlink"
        return 1
    fi

    local temp_skill="$HOME/.claude/skills/$skill_name"
    local dotfiles_skill="$DOTFILES_DIR/dot_claude/skills/$skill_name"

    if [ ! -d "$temp_skill" ]; then
        echo "Error: Skill not found in ~/.claude/skills/$skill_name"
        echo "Use 'claude-skill-try $skill_name' to create it first"
        return 1
    fi

    if [ -L "$temp_skill" ]; then
        echo "Skill is already promoted (symlink detected)"
        echo "Location: $(readlink $temp_skill)"
        return 0
    fi

    if [ -d "$dotfiles_skill" ]; then
        echo "Error: Skill already exists in dotfiles: $dotfiles_skill"
        return 1
    fi

    echo "Moving skill to dotfiles..."
    mv "$temp_skill" "$dotfiles_skill"

    ln -sf "$dotfiles_skill" "$temp_skill"

    echo "Skill promoted to dotfiles"
    echo "  Dotfiles location: $dotfiles_skill"
    echo "  Symlink created: $temp_skill -> $dotfiles_skill"
    echo ""
    echo "Next steps:"
    echo "  cd $DOTFILES_DIR"
    echo "  git add dot_claude/skills/$skill_name"
    echo "  git commit -m 'Add $skill_name skill'"
}

claude-skill-list() {
    echo "=== Claude Code Custom Skills ==="
    if [ -d "$DOTFILES_DIR/dot_claude/skills" ]; then
        ls -1 "$DOTFILES_DIR/dot_claude/skills"
    else
        echo "No custom skills found"
    fi

    echo ""
    echo "=== Marketplace Skills ==="
    if [ -f "$DOTFILES_DIR/dot_claude/marketplace-skills.txt" ]; then
        grep -v "^#" "$DOTFILES_DIR/dot_claude/marketplace-skills.txt" | grep -v "^$"
    else
        echo "No marketplace skills configured"
    fi
}

# ============ Codex CLI skill management ============
codex-skill-try() {
    local skill_name="$1"
    if [ -z "$skill_name" ]; then
        echo "Usage: codex-skill-try <skill-name>"
        echo "  Creates a temporary skill in ~/.codex/skills/ for testing"
        echo "  Use 'codex-skill-promote' to move it to dotfiles when ready"
        return 1
    fi

    if [ -L "$HOME/.codex/skills" ]; then
        echo "Error: ~/.codex/skills is entirely symlinked to dotfiles"
        echo "Create skill directly in dotfiles instead:"
        echo "  mkdir -p $DOTFILES_DIR/dot_codex/skills/$skill_name"
        return 1
    fi

    local skill_dir="$HOME/.codex/skills/$skill_name"
    if [ -d "$skill_dir" ]; then
        echo "Skill already exists: $skill_dir"
        ${EDITOR:-vim} "$skill_dir/SKILL.md"
        return 0
    fi

    mkdir -p "$skill_dir"
    cat > "$skill_dir/SKILL.md" <<EOF
---
name: $skill_name
description:
---

# $skill_name

## 概要

## 主要原則

## チェックリスト

- [ ]
EOF

    echo "Created temporary skill: $skill_dir/SKILL.md"
    echo "Try it out, then run 'codex-skill-promote $skill_name' to add to dotfiles"
    ${EDITOR:-vim} "$skill_dir/SKILL.md"
}

codex-skill-promote() {
    local skill_name="$1"
    if [ -z "$skill_name" ]; then
        echo "Usage: codex-skill-promote <skill-name>"
        echo "  Moves skill from ~/.codex/skills/ to dotfiles"
        return 1
    fi

    local temp_skill="$HOME/.codex/skills/$skill_name"
    local dotfiles_skill="$DOTFILES_DIR/dot_codex/skills/$skill_name"

    if [ -L "$HOME/.codex/skills" ]; then
        echo "Note: ~/.codex/skills is entirely symlinked"
        if [ -d "$dotfiles_skill" ]; then
            echo "Skill already exists in dotfiles: $dotfiles_skill"
        else
            echo "Skill not found. It may already be in dotfiles."
        fi
        return 0
    fi

    if [ ! -d "$temp_skill" ]; then
        echo "Error: Skill not found in ~/.codex/skills/$skill_name"
        echo "Use 'codex-skill-try $skill_name' to create it first"
        return 1
    fi

    if [ -d "$dotfiles_skill" ]; then
        echo "Error: Skill already exists in dotfiles: $dotfiles_skill"
        return 1
    fi

    echo "Moving skill to dotfiles..."
    mv "$temp_skill" "$dotfiles_skill"

    echo "Skill promoted to dotfiles"
    echo "  Dotfiles location: $dotfiles_skill"
    echo ""
    echo "Next steps:"
    echo "  cd $DOTFILES_DIR"
    echo "  git add dot_codex/skills/$skill_name"
    echo "  git commit -m 'Add $skill_name skill'"
}

codex-skill-list() {
    echo "=== Codex CLI Custom Skills ==="
    if [ -d "$DOTFILES_DIR/dot_codex/skills" ]; then
        ls -1 "$DOTFILES_DIR/dot_codex/skills"
    else
        echo "No custom skills found"
    fi
}

alias vercel='npx vercel@latest'

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

export PATH=$PATH:$HOME/.maestro/bin
