#!/usr/bin/env bash
# Stop / SubagentStop tripwire.
# 最終アシスタントメッセージに生のツール呼び出しマークアップ(invoke/parameter タグ)が
# 漏れていれば block して再生成を強制する。クリーンになるまで粘る(撤退・回数制限なし)。
# hook 自身がエラー/判定不能なときだけ exit 0 (fail open) で通常作業を止めない。
set -u

input="$(cat)"

# jq が無ければ判定不能 → fail open
command -v jq >/dev/null 2>&1 || exit 0

transcript="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)"
if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  exit 0
fi

# 最後の assistant メッセージのテキスト内容(壊れた行はスキップ)
last_text="$(jq -R 'fromjson? // empty' "$transcript" 2>/dev/null | jq -rs '
  map(select(.type=="assistant")) | last
  | (.message.content // [])
  | map(select(.type=="text") | .text) | join("\n")
' 2>/dev/null)"
[ -z "$last_text" ] && exit 0

# コードフェンス内の言及は除外し誤検知を防ぐ
stripped="$(printf '%s\n' "$last_text" | sed '/^[[:space:]]*```/,/^[[:space:]]*```/d')"

# 漏れ署名: invoke タグと parameter タグが地の文に共起、
# または function-call ラッパ / 閉じ invoke タグが地の文に出現
leak=0
# 単独でも漏れの署名を機械検知（このユーザーの通常出力に court/invoke 系タグはまず出ない前提）。
# コードフェンス内は除外済みなので、説明をフェンスに入れる限り誤検知しない。
if printf '%s' "$stripped" | grep -qE '<invoke|<parameter|<function_calls>|</invoke>|</antml'; then
  leak=1
fi
# 壊れた前置トークン court: 単独行、またはタグに隣接して出現
if printf '%s' "$stripped" | grep -qE '^[[:space:]]*court[[:space:]]*$' \
   || printf '%s' "$stripped" | grep -qE 'court[[:space:]]*<'; then
  leak=1
fi

if [ "$leak" -eq 1 ]; then
  jq -n '{
    decision: "block",
    reason: "最終メッセージに生のツール呼び出しマークアップ(invoke/parameter タグ)が混入しています。意図したツール呼び出しは正規の function-call チャネルで出し直し、地の文にタグを書かないクリーンな最終メッセージを再生成してください。ユーザーへの謝罪・通知は不要。正しく出せるまで粘ること(撤退しない)。直前に化けた出力を見た場合は文脈を信頼せず、単一・最小のツール呼び出しで ground truth を取り直すこと。復旧できたら run-toolcall-recover スキルの手順に従い、止まった原因と効いた手を notes.md に追記すること(この場でスキル/フック本体は編集しない。改善は後でクリーンな文脈から run-toolcall-improve で行う)。"
  }'
fi

exit 0
