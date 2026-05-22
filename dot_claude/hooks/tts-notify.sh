#!/bin/bash
# Stop hook: announce task completion via macOS say (background, non-blocking).
# macOS only; no-op on other platforms.

set -euo pipefail

[[ "$(uname)" != "Darwin" ]] && exit 0
command -v say > /dev/null 2>&1 || exit 0

messages=(
    "完了です"
    "終わったよ"
    "お疲れさま"
    "できました"
    "本当に偉い"
    "ごきげんよう"
    "パン"
    "良い夢を"
)
msg="${messages[$RANDOM % ${#messages[@]}]}"

say -v Kyoko "$msg" > /dev/null 2>&1 &
disown

exit 0
