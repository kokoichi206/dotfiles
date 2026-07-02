#!/usr/bin/env bash
# PreToolUse guard: PR マージ操作は必ずユーザーの明示承認を挟む。
# Bash の `gh pr merge` 系コマンド、および mcp__github__merge_pull_request の呼び出しを
# 検知したら permissionDecision "ask" を返し、人間の確認を強制する。
# defaultMode: auto でも例外を作らない(自律マージ禁止の原則をツール層で担保する)。
# jq が無い / 入力が壊れている等で判定不能なときだけ exit 0 (fail open) で通常フローに委ねる。
set -u

input="$(cat)"

# jq が無ければ判定不能 → fail open
command -v jq >/dev/null 2>&1 || exit 0

tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
[ -z "$tool_name" ] && exit 0

reason="PR マージはユーザーの明示承認が必要。マージ可能と報告して指示を待つこと。"

ask() {
  jq -n --arg r "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

case "$tool_name" in
  mcp__github__merge_pull_request)
    ask
    ;;
  Bash)
    cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
    # `gh pr merge`(空白は可変、merge の後は空白か行末) を含むコマンドを検知
    if printf '%s' "$cmd" | grep -qE 'gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)'; then
      ask
    fi
    ;;
esac

exit 0
