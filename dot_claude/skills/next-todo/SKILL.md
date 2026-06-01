---
name: overdue-tasks
description: GitHub Project v2 から期日超過・期日当日のタスクを取得して表示する。トリガー - 期限切れタスク, overdue, 期日超過, タスク確認, 今日のタスク, やり残し
---

# GitHub Project 期日超過タスク取得

GitHub Project v2 から、指定日以前が期日のタスクを一覧表示する。

## 実行コマンド

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-overdue.sh [user] [project-number] [date]
```

## パラメータ

| パラメータ | デフォルト | 説明 |
|-----------|----------|------|
| user | kokoichi206 | GitHub ユーザー名 |
| project-number | 4 | プロジェクト番号 |
| date | 今日 | 基準日（YYYY-MM-DD） |

## 使用例

### 今日以前の期日超過タスクを確認

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-overdue.sh
```

### 特定日を基準に確認

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-overdue.sh kokoichi206 4 2026-04-20
```

## 前提条件

- `gh` CLI がインストール済みで認証済み
- gh のトークンに `read:project` スコープがあること（`gh auth refresh -s read:project` で追加可能）
- プロジェクトに `DueDate`（DATE 型）と `Status`（SingleSelect 型）フィールドがあること

## 出力

期日降順で以下の形式：

```
YYYY-MM-DD  [Status]  タスク名  URL
```

## 実行手順

1. コマンドを実行して期日超過タスクの一覧を取得する
2. Done 以外のタスクをユーザーに提示する
3. ユーザーの指示に応じて個別タスクの詳細確認や issue のクローズを行う
