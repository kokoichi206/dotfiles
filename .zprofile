# ログイン時に一度だけ必要なツール環境を初期化する。

eval "$(/opt/homebrew/bin/brew shellenv)"

source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || :
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -r "$HOME/.ghcup/env" ]] && source "$HOME/.ghcup/env"

# 上の各ツールが PATH を書き換えたあとで .zshenv の優先順を戻す。
# brew shellenv は /opt/homebrew を先頭へ差し込むため、ここで入れ直さないと
# mise の project ごとの tool version と Home Manager 所有のツールが brew に負ける。
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/mise/shims"
  "/etc/profiles/per-user/${USERNAME}/bin"
  "$HOME/.nix-profile/bin"
  "/run/current-system/sw/bin"
  "/nix/var/nix/profiles/default/bin"
  $path
)
