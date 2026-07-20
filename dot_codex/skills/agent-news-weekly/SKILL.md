---
name: agent-news-weekly
description: "直近1週間の LLM/Agent (coding/image/video) ニュースを定点ソースと X 検索で独立調査し、Claude Code 版レポートとの突合用ドラフト (report.md / actions.md) を news/agent-weekly/<date>/codex/ に生成する。調査とドラフト生成のみを行い、Claude 版成果物の編集・統合・issue 化・設定変更は行わない (突合と統合は呼び出し側フローの担当)。"
metadata:
  short-description: agent-news weekly independent draft for cross-check (codex)
---

# agent-news-weekly (codex)

対象期間は実行日を含む過去 7 日。実行日は `date +%F` で確定する。

Claude Code 版 (`dot_claude/skills/agent-news-weekly`) と併走する独立調査ドラフト。
`references/` と `scripts/` は Claude 版への symlink で共有しており、ソース定義・出力契約・実測スクリプトの変更は両版へ同時に反映される。

## 独立性の契約 (突合の価値の源泉)

- Claude 版の成果物 (report.html / report.md / actions.md) は**読まない**。
  読んでしまうと突合が「答え合わせの写経」になり検証価値が消える。ソースへ直接あたる。
- 突合・統合はこの skill の境界外。呼び出し側プロンプトが行う。

## 出力契約 (パス・形式は変更禁止 — 突合フローが依存する)

出力先は**実行時 cwd が属する git リポジトリのルート** (`git rev-parse --show-toplevel` で確定) 直下。

```
<repo>/news/agent-weekly/<YYYY-MM-DD>/codex/
├── report.md     # markdown レポート (セクション構成は Claude 版 report.md と同一)
└── actions.md    # 押さえどころチェックリスト (スキーマは references/output-contract.md)
```

- `<YYYY-MM-DD>` は突合対象の日付ディレクトリ (通常は news/agent-weekly/ 配下の最新)。
  対象ディレクトリが存在しない単独実行では実行日を使う。
- report.html は作らない (人間閲覧用 HTML は Claude 版の担当)。
- codex/ の外 (Claude 版の report.* / actions.md / runs.jsonl) には書き込まない。
  runs.jsonl への記録は突合まで終えた呼び出し側フローが 1 行で行う (二重記録を防ぐ)。
- git リポジトリ外で実行された場合は、別の場所へ書かずに停止してユーザーへ報告する (暗黙 fallback 禁止)。
- レポートの実測には業務リポ名・トークン数が入る。出力先リポジトリが **public** の場合は
  `news/agent-weekly/` が .gitignore 済みであることを確認してから書く。未登録なら書かずにユーザーへ確認する。

## 手順

1. **期間確定**: 実行日と 7 日前の日付を出す。
2. **調査**: [references/sources.md](references/sources.md) のソース一覧・取得方法・403 時の fallback に従い、
   ①Claude Code/Anthropic ②OpenAI/Codex ③xAI/Grok ④その他 coding agent・モデル・画像・動画 を順に調査する。
   fetch した内容のみを報告に使い、取得失敗・制限は必ず記録する。
3. **X 検索**: grok CLI で開発者事例 (オーケストレーション / hooks・skills / grok CLI 実践 / 日本) を収集する。
   実行方法は references/sources.md の grok CLI 節。
4. **ローカル実測**: `scripts/scan_transcripts.py --days 7` を実行し、
   [references/output-contract.md](references/output-contract.md) の静的チェック一覧を実施する。
   dotfiles を重点、他リポジトリは全般傾向のみ。credential 類の走査が権限拒否されたら回避せず「手元確認を推奨」として記録する。
5. **ドラフト生成**: 下の構成規則で report.md / actions.md を書く。

## レポート構成規則 (Claude 版と揃えること — 突合はセクション単位で行われる)

- セクション構成: タイムライン / Claude Code / Codex / xAI / その他 coding agent / モデル・フレームワーク / 画像・動画 / 押さえどころ (あなた向け) / X 事例 + ブログ定点観測 / 取得失敗・制限。
- **他ツール比較はインライン**。各リリースカード内に「他ツール比較」ボックスを置き、独立の機能対応マップは作らない。
- 押さえどころは各項目に「刺さる理由 (1 行)」と「実測」を付け、実測に基づく判定 (今すぐ / 今週中 / 不要) を明示する。
- 二次ソース由来は「△ 二次ソース」と明記し、一次未検証の数値を断定しない。
- **取得失敗・制限は最終セクションに全件明記する** (サイレントで落とさない)。実測の範囲と除外も書く。

## 失敗時の記録

- 部分失敗 (一部ソース 403、grok 実行不可など): ドラフトは生成し、取得失敗・制限セクションに列挙する。
- 全滅 (ドラフト生成不能): `news/agent-weekly/<date>/codex/FAILED.md` にエラー内容と再実行手順を書いて停止する。

## やらないこと (境界)

- Claude 版成果物の閲覧・編集・統合 (呼び出し側フローの担当)。
- runs.jsonl への追記 (呼び出し側フローの担当)。
- issue / PR の作成、設定ファイルの変更、ツール・skill の導入、git commit。
