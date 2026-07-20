# ============ Shell behavior ============
# 貼り付けた shell snippet のコメント行を対話シェルでも無視する
setopt INTERACTIVE_COMMENTS

# `/` を除外して `origin/main` のようなパスを Ctrl+W / Option+Delete で
# 一語ずつ消せるようにする。デフォルト値から差分だけを引く形で書く。
WORDCHARS=${WORDCHARS:s@/@}

# ============ Abbreviations (zsh-abbr) ============
# パイプや ; && || の後（コマンド位置）でも regular 略語を展開する。引数位置では展開しない。
# sheldon が zsh-abbr を読み込む前に設定する必要がある。
# https://github.com/olets/zsh-abbr/issues/53
export ABBR_EXPERIMENTAL_COMMAND_POSITION_REGULAR_ABBREVIATIONS=2
export ABBR_USER_ABBREVIATIONS_FILE="${XDG_CONFIG_HOME}/zsh-abbr/user-abbreviations"

# ============ Sheldon (plugin manager) ============
eval "$(sheldon source)"

# ============ Completion ============
# completionを追加するツールはcompinitより前にfpathへ登録する。
fpath=("$HOME/.grok/completions/zsh" $fpath)
autoload -Uz compinit
# compinit の再生成は1日1回に抑える
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
autoload -U +X bashcompinit && bashcompinit

DOTFILES_DIR="$HOME/ghq/github.com/kokoichi206/dotfiles"

source "$XDG_CONFIG_HOME/zsh/aliases.zsh"
source "$XDG_CONFIG_HOME/zsh/history.zsh"
source "$XDG_CONFIG_HOME/zsh/functions.zsh"
source "$XDG_CONFIG_HOME/zsh/claude-functions.zsh"
source "$XDG_CONFIG_HOME/zsh/codex-functions.zsh"

# precmd/chpwd hookとpromptの初期化は、他の定義を読み込んだ後に行う。
source "$XDG_CONFIG_HOME/zsh/integrations.zsh"
