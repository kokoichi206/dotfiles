#!/bin/bash
# WezTerm の user-var-changed イベントを発火させ、Claude Code が動いているペイン/タブを活性化する。
# WezTerm 側のハンドラ: .config/wezterm/wezterm.lua の "user-var-changed" イベント
printf '\033]1337;SetUserVar=claude_code_stop=%s\007' MQ== > /dev/tty

# WezTerm ウィンドウ自体を前面に持ってくる
osascript -e 'tell application "WezTerm" to activate'
