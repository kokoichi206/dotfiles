#!/usr/bin/env bash
# detect-toolcall-leak.sh 回帰テスト（6パターン）
# 罠対策: jq -nc で1行JSONL、フェンスは素のバックティック
hook="$HOME/.claude/hooks/detect-toolcall-leak.sh"
pass=0; fail=0

run_case() {
  local name="$1" text="$2" expect="$3"  # expect: block | none
  local t; t=$(mktemp)
  jq -nc --arg s "$text" '{type:"assistant",message:{content:[{type:"text",text:$s}]}}' > "$t"
  local out; out=$(printf '{"transcript_path":"%s"}' "$t" | "$hook")
  local got="none"
  printf '%s' "$out" | grep -q '"decision"' && printf '%s' "$out" | grep -q 'block' && got="block"
  if [ "$got" = "$expect" ]; then
    echo "PASS: $name (expect=$expect)"; pass=$((pass+1))
  else
    echo "FAIL: $name (expect=$expect got=$got)"; fail=$((fail+1))
  fi
  rm -f "$t"
}

tag_open='<invoke name="Bash">'
tag_param='<parameter name="command">ls</parameter>'
wrapper='<function_calls>'

# 1. 漏れ: invoke + parameter タグが地の文に
run_case "leak-tags" "作業を続けます。
court ${tag_open}
${tag_param}" "block"

# 2. クリーンな通常出力
run_case "clean" "ファイルを3つ更新しました。テストも通っています。courtesy call の件は別途。" "none"

# 3. フェンス内の例示（素のバックティック）
run_case "fenced" "例を示します:
\`\`\`
court ${tag_open}
${tag_param}
${wrapper}
\`\`\`
以上が漏れの例です。" "none"

# 4. 単独 court 行
run_case "solo-court-line" "処理中です。
court
次に進みます。" "block"

# 5. 文中の court（英単語として）
run_case "court-in-sentence" "The court ruled in favor. Supreme Court decision was final." "none"

# 6. 単独タグ（ラッパのみ）
run_case "solo-wrapper-tag" "結果は以下です。
${wrapper}
done" "block"

echo "---"
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
