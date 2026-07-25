# 全ての zsh から参照する、実行を伴わない環境変数とPATHを定義する。
export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="nvim"
export LANG="en_US.UTF-8"

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/mise/shims"
  "$HOME/.grok/bin"
  "$HOME/.maestro/bin"
  "$HOME/.codeium/windsurf/bin"
  "$HOME/Library/Android/sdk/platform-tools"
  "$HOME/go/bin"
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/opt/homebrew/opt/openssl@3/bin"
  "/opt/homebrew/opt/postgresql@16/bin"
  $path
)
export PATH
