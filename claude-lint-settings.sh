#!/bin/sh
#
# Description:
#   dot_claude/settings.json の hook 配線を検査する。
#   `make claude-pull` は live 設定で repo を丸ごと上書きするため、
#   live 側で未配線の hook は pull のたびに repo からも消える。
#   配線の消失と、実体のない hook 参照を commit 前に検出する。
set -eu

SETTINGS="dot_claude/settings.json"
HOOKS_DIR="dot_claude/hooks"

# 意図的に未配線の hook。配線するときはここから外すこと。
UNWIRED="focus-wezterm.sh rtk-rewrite.sh"

fail=0

# 壊れた JSON なら以降の検査は無意味なのでここで止める
jq -e . "$SETTINGS" >/dev/null

# 1. hooks 実体がすべて settings.json から参照されていること
for path in "$HOOKS_DIR"/*.sh "$HOOKS_DIR"/*.py; do
  [ -e "$path" ] || continue
  f="$(basename "$path")"
  case " $UNWIRED " in *" $f "*) continue ;; esac
  case "$f" in test-*) continue ;; esac
  if ! grep -q "hooks/$f" "$SETTINGS"; then
    echo "ERROR: $HOOKS_DIR/$f is not wired in $SETTINGS" >&2
    fail=1
  fi
done

# 2. settings.json が参照する $HOME/.claude/hooks/ 配下のスクリプトが repo に実在すること
#    ($CLAUDE_PROJECT_DIR 配下などプロジェクトスコープの hook は対象外)
for f in $(jq -r '[.hooks[][]? | .hooks[]?.command] | join("\n")' "$SETTINGS" \
  | grep -oE '\$HOME/\.claude/hooks/[A-Za-z0-9._-]+' | sed 's#.*/##' | sort -u); do
  if [ ! -e "$HOOKS_DIR/$f" ]; then
    echo "ERROR: $SETTINGS references hooks/$f but $HOOKS_DIR/$f does not exist" >&2
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: hook wiring is consistent"
fi
exit "$fail"
