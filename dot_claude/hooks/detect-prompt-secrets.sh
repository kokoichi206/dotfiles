#!/usr/bin/env bash
# UserPromptSubmit tripwire.
# プロンプトに API キーらしき文字列(主要プロバイダの既知接頭辞)が含まれていたら、
# ブロックせず additionalContext で取り扱い注意を注入する。
# キーの貼付自体は正当な作業(検証・デバッグ)でありうるため block はしない。
# hook 自身がエラー/判定不能なときだけ何も出さず exit 0 (fail open) で通常作業を止めない。
set -u

input="$(cat)"

# jq が無ければ判定不能 → fail open
command -v jq >/dev/null 2>&1 || exit 0

prompt="$(printf '%s' "$input" | jq -r '.user_prompt // empty' 2>/dev/null)"
[ -z "$prompt" ] && exit 0

# 主要 API キーの既知接頭辞:
# OpenRouter / OpenAI(project) / Anthropic / Stripe(live) / AWS / GitHub(PAT) / Slack / Google
pattern='sk-or-v1-[A-Za-z0-9]{8}'
pattern="$pattern|sk-proj-[A-Za-z0-9_-]{8}"
pattern="$pattern|sk-ant-[A-Za-z0-9_-]{8}"
pattern="$pattern|sk_live_[A-Za-z0-9]{8}"
pattern="$pattern|AKIA[0-9A-Z]{16}"
pattern="$pattern|ghp_[A-Za-z0-9]{8}"
pattern="$pattern|github_pat_[A-Za-z0-9_]{8}"
pattern="$pattern|xox[bp]-[A-Za-z0-9-]{8}"
pattern="$pattern|AIza[0-9A-Za-z_-]{16}"

if printf '%s' "$prompt" | grep -qE "$pattern"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: "プロンプトに API キーらしき文字列が含まれています。取り扱い注意: (1) キーの値をファイル・コミット・PR・issue・コード例に書き込まない。(2) コマンドに埋め込む場合も、シェル履歴やログに平文で残る形を避ける。(3) プロンプト自体が transcript に平文で残るため、作業完了後にこのキーを無効化(rotate)することをユーザーに推奨する。"
    }
  }'
fi

exit 0
