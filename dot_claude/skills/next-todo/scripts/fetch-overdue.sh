#!/bin/bash
# GitHub Project v2 から期日超過タスクを取得する
# Usage: ./fetch-overdue.sh [user] [project-number] [date]
#   user:           GitHub ユーザー名（デフォルト: kokoichi206）
#   project-number: プロジェクト番号（デフォルト: 4）
#   date:           基準日 YYYY-MM-DD（デフォルト: 今日）
#
# Done は対応不要のため取得段階でサーバー側フィルタ（items の query 引数）で除外する。
# query の field slug は field 名を小文字化したもの（DueDate → duedate）。
# ハイフン区切り（due-date）は何にも一致せず 0 件になるので使わない。

USER="${1:-kokoichi206}"
PROJECT="${2:-4}"
DATE="${3:-$(date +%Y-%m-%d)}"

FILTER="-status:Done duedate:<=${DATE}"

# items は 100 件/ページ。endCursor で全ページ回収しないと超過分が静かに欠落する。
nodes="[]"
title=""
cursor="null"
while :; do
  resp=$(gh api graphql -f query="
{
  user(login: \"${USER}\") {
    projectV2(number: ${PROJECT}) {
      title
      items(first: 100, after: ${cursor}, query: \"${FILTER}\") {
        pageInfo { hasNextPage endCursor }
        nodes {
          content {
            ... on Issue {
              title
              url
              number
              state
            }
            ... on DraftIssue {
              title
            }
          }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldDateValue {
                date
                field { ... on ProjectV2Field { name } }
              }
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
            }
          }
        }
      }
    }
  }
}") || exit 1
  title=$(jq -r '.data.user.projectV2.title' <<<"$resp")
  nodes=$(jq --argjson acc "$nodes" '$acc + .data.user.projectV2.items.nodes' <<<"$resp")
  [ "$(jq -r '.data.user.projectV2.items.pageInfo.hasNextPage' <<<"$resp")" = "true" ] || break
  cursor="\"$(jq -r '.data.user.projectV2.items.pageInfo.endCursor' <<<"$resp")\""
done

# 期日・Status の抽出と整形。期日条件はサーバー側と同じ述語を表示前にも適用する
# （query が構文変更等で素通しになった場合に期日超過以外が混ざるのを防ぐ）。
jq -r --arg date "$DATE" --arg title "$title" '
  "\($title) — 期日が \($date) 以前の未完了タスク\n",
  (.[]
    | . as $item
    | ($item.fieldValues.nodes[] | select(.field.name == "DueDate") | .date) as $due
    | ($item.fieldValues.nodes[] | select(.field.name == "Status") | .name) // "-" |
    . as $status
    | select($due != null and $due <= $date)
    | "\($due)  [\($status)]  \($item.content.title // "(draft)")  \($item.content.url // "")"
  )
  | split("\n") | sort | reverse | .[]
' <<<"$nodes"
