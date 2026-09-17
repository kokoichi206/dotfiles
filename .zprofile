# ログイン時に一度だけ必要なツール環境を初期化する。

eval "$(/opt/homebrew/bin/brew shellenv)"

source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -r "$HOME/.ghcup/env" ]] && source "$HOME/.ghcup/env"

# 上の各ツールが PATH を書き換えたあとで mise shims を先頭に戻す。
# .zshrc を読まない非対話シェルでも project ごとの tool version を解決させるため。
typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/.local/share/mise/shims" $path)
