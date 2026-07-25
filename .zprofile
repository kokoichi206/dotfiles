# ログイン時に一度だけ必要なツール環境を初期化する。

eval "$(/opt/homebrew/bin/brew shellenv)"

source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -r "$HOME/.ghcup/env" ]] && source "$HOME/.ghcup/env"
