---
name: sentry-hotfix-loop
description: Sentry issue の調査から修正検証までを統一手順で実施する。Sentry, 本番エラー, issue 対応, trace 調査, hotfix の依頼時は必ず使う。
---

# Sentry Hotfix Loop

Sentry 障害対応を、再現性と説明責任を保ったまま進めるためのスキル。

## 前提

認証は `~/.sentryclirc` のトークンを自動で読む。org slug は `sentry-cli organizations list` から取得する。環境変数 (`SENTRY_AUTH_TOKEN`, `SENTRY_ORG_SLUG`) が設定されていればそちらを優先する。

curl がエイリアスで上書きされている環境では `CURL=/usr/bin/curl` を指定する。

## 手順

0. 未解決 issue をトリアージする（issue ID が未定の場合）
- `scripts/fetch_issue_context.sh --list [project-slug]`
- 出力: shortId, level, count, title の一覧

1. issue コンテキストを取得する
- `scripts/fetch_issue_context.sh <issue-short-id> <output-dir>`
- 出力: `issue.json`, `events.json`, `tags.json`

2. イベントタイプを判定する
- `jq -r '.type' <output-dir>/issue.json` で `error` か `default`(message) か確認
- **exception (error)**: stacktrace を起点に原因を追う
- **message (default)**: stacktrace がない。コード内でこのメッセージを出している箇所を grep し、呼び出し元を追う。breadcrumbs からユーザー操作の流れを確認する

3. 再現チェックリストを作る
- `python3 scripts/build_repro_checklist.py <issue.json> <repro.md>`
- 期待: 失敗条件、影響範囲、観測ログ、検証方法

4. 修正を実装する
- 根本原因に直接効く変更だけを入れる
- 暗黙的 fallback を追加しない

5. 修正検証を実行する
- `scripts/verify_fix.sh <checks.txt> <report.md>`
- `checks.txt` は 1 行 1 コマンド

6. 報告する
- 原因
- 修正
- 検証結果
- 残課題

## scripts

- `scripts/fetch_issue_context.sh`: Sentry API から issue 情報を収集
- `scripts/build_repro_checklist.py`: 再現手順の雛形を生成
- `scripts/verify_fix.sh`: 検証コマンドを一括実行

## references

- `references/triage-playbook.md`
- `references/postmortem-template.md`

## examples

- `examples/payments-timeout.md`
