#!/bin/bash
# GitHub Project v2 から期日超過タスクを取得する
# Usage: ./fetch-overdue.sh [user] [project-number] [date]
#   user:           GitHub ユーザー名（デフォルト: kokoichi206）
#   project-number: プロジェクト番号（デフォルト: 4）
#   date:           基準日 YYYY-MM-DD（デフォルト: 今日）

USER="${1:-kokoichi206}"
PROJECT="${2:-4}"
DATE="${3:-$(date +%Y-%m-%d)}"

gh api graphql -f query="
{
  user(login: \"${USER}\") {
    projectV2(number: ${PROJECT}) {
      title
      items(first: 100) {
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
}" | jq -r --arg date "$DATE" '
  .data.user.projectV2 as $proj |
  "\($proj.title) — 期日が \($date) 以前のタスク\n",
  ($proj.items.nodes[]
    | . as $item
    | ($item.fieldValues.nodes[] | select(.field.name == "DueDate") | .date) as $due
    | ($item.fieldValues.nodes[] | select(.field.name == "Status") | .name) // "-" |
    . as $status
    | select($due != null and $due <= $date)
    | "\($due)  [\($status)]  \($item.content.title // "(draft)")  \($item.content.url // "")"
  )
  | split("\n") | sort | reverse | .[]
'
