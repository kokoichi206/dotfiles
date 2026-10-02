#!/usr/bin/env bash
# detect-prompt-secrets.sh 回帰テスト
# 罠対策: キー例はダミー値。実キーをテストに書かない
hook="$(cd "$(dirname "$0")" && pwd)/detect-prompt-secrets.sh"
pass=0; fail=0

run_case() {
  local name="$1" prompt="$2" expect="$3"  # expect: context | none
  local out; out=$(jq -nc --arg p "$prompt" '{hook_event_name:"UserPromptSubmit",user_prompt:$p}' | "$hook")
  local got="none"
  printf '%s' "$out" | grep -q '"additionalContext"' && got="context"
  if [ "$got" = "$expect" ]; then
    echo "PASS: $name (expect=$expect)"; pass=$((pass+1))
  else
    echo "FAIL: $name (expect=$expect got=$got)"; fail=$((fail+1))
  fi
}

# 1. OpenRouter キー
run_case "openrouter" "このキーで叩いて: sk-or-v1-0123456789abcdef0123456789abcdef" "context"

# 2. OpenAI project キー
run_case "openai-proj" "sk-proj-abcDEF123456_789 を env に入れたい" "context"

# 3. AWS アクセスキー ID
run_case "aws-akia" "AKIAIOSFODNN7EXAMPLE でアクセスできるか確認して" "context"

# 4. GitHub PAT (classic)
run_case "github-ghp" "token は ghp_abcdefghijklmnop1234 です" "context"

# 5. GitHub PAT (fine-grained)
run_case "github-fine-grained" "github_pat_11ABCDEFG_xyz789 を使って" "context"

# 6. Slack bot token
run_case "slack-xoxb" "xoxb-1234567890-abcdefg で投稿して" "context"

# 7. Stripe live キー
run_case "stripe-live" "sk_live_abcdef1234567890 の挙動を調べて" "context"

# 8. クリーンな通常プロンプト
run_case "clean" "PR を作って。ブランチ名は feat/add-hook で" "none"

# 9. 接頭辞に言及するだけ(実キーなし)
run_case "prefix-mention" "sk-proj- で始まるキーの形式について教えて" "none"

# 10. AKIA を含む普通の単語
run_case "akia-in-word" "AKIAKANE という名前のプロジェクトです" "none"

echo "---"
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
