---
name: next-todo
description: GitHub Project v2 から期日超過・期日当日のタスクを取得し、各 issue の詳細を確認して取るべきアクションに整理する。トリガー - 期限切れタスク, overdue, 期日超過, タスク確認, 今日のタスク, やり残し, 次にやること, アクション化
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

### フェーズ1: 一覧取得と提示

1. コマンドを実行して期日超過タスクの一覧を取得する
2. `[Done]` を除外し、Done 以外のタスクだけをユーザーに提示する（Done は完了済みなので対応不要）

### フェーズ2: 詳細確認とアクション化

ユーザーが「アクションに起こして」「次に何をすべきか」「詳細を確認して」と求めた場合、Done 以外の各タスクについて以下を行う。

1. **issue 本文・コメントを取得する**
   一覧の URL から `owner/repo` と issue 番号を読み取る（プロジェクトには複数 repo の issue が混在しうるので、URL ごとに判別する）。Done 以外を並列でまとめて取得する。

   ```bash
   gh issue view <number> --repo <owner>/<repo> \
     --json number,title,body,comments,createdAt,updatedAt,state,labels
   ```

2. **判断材料を補う**
   - body / comments に公開 URL があれば取得し、締切・申込可否などの判断材料を補完する。
   - private リンク（`*.slack.com` などアクセス不可なもの）は推測で埋めず、「リンク先を要確認」として残す。

3. **アクションに変換する**
   各タスクを「次に取るべき具体的な一手」に書き換える。優先度は **経過日数の長さではなく不可逆リスクの大きさ**で並べ替える。
   - 自動課金・解約期限（放置すると課金が始まり、巻き戻せない）→ 最優先
   - 申込・エントリー締切（過ぎると機会損失が確定する）→ まず可否を確認
   - 外部締切のない技術調査タスク → 緊急度を下げる

4. **表でまとめる**
   `期日 / 経過日数 / Status / タスク / 次の一手 / Issue` の形式で提示し、各タスクに concrete next action を 1〜2 個添える。完了済み・対応不要と判明したものは issue クローズを提案する。
