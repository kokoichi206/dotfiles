# 全ての zsh から参照する、実行を伴わない環境変数とPATHを定義する。
export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="nvim"
export LANG="en_US.UTF-8"

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/mise/shims"
  # ユーザー向け CLI ツールの所有者は Home Manager。
  # brew に同名バイナリが依存として残っても nix 側が使われるよう /opt/homebrew より前に置く。
  # nix-darwin モジュール版は /etc/profiles/per-user、単体版は ~/.nix-profile へ置く。
  # ~/.nix-profile には `nix profile install` の手動導入も混ざるため、
  # Home Manager 管理下の /etc/profiles/per-user を先に引く。
  "/etc/profiles/per-user/${USERNAME}/bin"
  "$HOME/.nix-profile/bin"
  "/run/current-system/sw/bin"
  "/nix/var/nix/profiles/default/bin"
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

# nix-darwin の /etc/zshrc を読み込まない。
# history・completion・prompt は本 dotfiles 側で定義しており、
# /etc/zshrc の compinit と二重になる。keymap のみ .zshrc の bindkey -e で補う。
export NOSYSZSHRC=1
