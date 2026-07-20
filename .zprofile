# ログイン時に一度だけ必要なPATHとツール環境を初期化する。
typeset -U path PATH

eval "$(/opt/homebrew/bin/brew shellenv)"

source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -r "$HOME/.ghcup/env" ]] && source "$HOME/.ghcup/env"

path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/mise/shims"
  "$HOME/.grok/bin"
  "$HOME/.maestro/bin"
  "$HOME/.codeium/windsurf/bin"
  "$HOME/go/bin"
  "/opt/homebrew/opt/openssl@3/bin"
  "/opt/homebrew/opt/postgresql@16/bin"
  $path
)
export PATH
