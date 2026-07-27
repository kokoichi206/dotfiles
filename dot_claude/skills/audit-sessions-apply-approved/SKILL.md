---
name: audit-sessions-apply-approved
description: セッション監査 issue（audit-sessions-propose が作成）でチェック承認された候補だけを、既存 issue/PR とのトリアージを経て PR / issue 化する。/audit-sessions-apply-approved で能動的に呼び出したときのみ動く（自動発火しない）。
disable-model-invocation: true
---

# 承認済み監査候補の実装

audit-sessions-propose が書いた「セッション監査」issue のタスクリストのうち、
チェック済み（`- [x]`）の行だけを実装して PR / issue にする。

## 0. 対象 issue の解決

引数（`$ARGUMENTS`）はレポートパス or issue 番号。省略時は
`kokoichi206/tasks` の最新のオープンな「セッション監査」issue を対象にする:

```bash
gh issue list -R kokoichi206/tasks --state open \
  --search "セッション監査 in:title" --json number,title --jq '.[0]'
```

対象 issue が存在しなければ「監査 issue なし」と報告して正常終了する。

## 1. 承認ゲート

- **実装するのはチェック済み（`- [x]`）の行だけ。** 未チェックの行には一切手を付けない。
- チェックが 1 つも無ければ何もせず「承認済み候補なし」と報告して正常終了する。
  この承認ゲートがあるため、スケジュール実行（監査の翌日など）に載せてよい。
- タスクリストの形式は audit-sessions-propose の §5 が定義する。形式を変えるときは両スキルで揃えること。

## 2. チェック済みの各候補の処理

1. **トリアージ（重複回避）**: 対象リポの既存 issue / PR に同じ提案がないか必ず先に確認する。
   ```bash
   gh search issues --repo <owner>/<repo> --state all "<キーワード>"
   gh pr list --repo <owner>/<repo> --state all --search "<キーワード>"
   ```
   一致する open / 最近の issue・PR があればスキップし、そのリンクを結果に残す（重複を作らない）。
2. **出口の振り分け**:
   - 差分が確定するもの（lint ルール設定 / `settings.json` / hook / `CLAUDE.md` / スクリプト）→ PR。
   - 人間の設計が要るもの（新スキル / プロンプト改善 / 方針が割れるもの）→ issue。
3. **対象リポは allowlist に限る**: `kokoichi206` / `kokoichi206-sandbox` / `Wareware-PJ`
   （audit-sessions-propose の分析対象 allowlist と揃えること）。
   ハーネス系（settings / hook / skill / CLAUDE.md）は dotfiles、
   コード規約の lint ルールは対象リポそれぞれに作る。
4. PR はリポジトリの規約に従う（base ブランチ、PR タイトルの言語）。**マージはしない**（作成のみ）。
5. **監査 issue へ書き戻す**: 処理した行の末尾に `→ PR #N` / `→ issue #N` /
   `→ 既存 #N と重複のためスキップ` を追記し、結果一覧をコメントする。
   issue を閉じるかはユーザーに委ねる（未チェックの候補が残っている間は開けたままでよい）。
6. 作成した PR / issue のリンクと、重複でスキップしたものを一覧で報告する。
