---
name: agent-news-weekly
description: 直近1週間の LLM/Agent (coding/image/video) ニュースを定点ソースと X 検索で調査し、ローカル実測で優先度づけした 1 枚 HTML レポートを実行先リポジトリの news/agent-weekly/ に生成する。トリガー - /agent-news-weekly, 週次エージェントニュース, agent news weekly, scheduled task からの定期実行。調査と生成のみを行い、issue 化・設定変更・ツール導入は行わない (後続フローの担当)。
---

# agent-news-weekly

対象期間は実行日を含む過去 7 日。実行日は `date +%F` で確定する。

## 出力契約 (パス・形式は変更禁止 — issue 化フローが依存する)

出力先は**実行時 cwd が属する git リポジトリのルート** (`git rev-parse --show-toplevel` で確定) 直下。実行するリポジトリを変えれば出力先も変わる (cron は出力したいリポジトリへ cd してから実行する)。

- git リポジトリ外で実行された場合は、別の場所へ書かずに停止してユーザーへ報告する (暗黙 fallback 禁止)。
- レポートの実測には業務リポ名・トークン数が入る。出力先リポジトリが **public** の場合は `news/agent-weekly/` が .gitignore 済みであることを確認してから書く (dotfiles は登録済み)。未登録なら書かずにユーザーへ確認する。**private** (例: tasks) なら commit 可能だが、commit 自体はこの skill の境界外。

```
<repo>/news/agent-weekly/     # repo = 実行時の git ルート
├── runs.jsonl                # 実行記録。成功・部分失敗・失敗のすべてで追記 (リポジトリごとに持つ)
└── <YYYY-MM-DD>/             # 実行日
    ├── report.html           # 完成レポート (人間閲覧用)
    ├── report.md             # markdown 版 (diff・引用用)
    └── actions.md            # 押さえどころチェックリスト (issue 化フローの入力)
```

actions.md の項目スキーマ・runs.jsonl のスキーマ・実測の静的チェック一覧は [references/output-contract.md](references/output-contract.md) を読む。

## 手順

1. **期間確定**: 実行日と 7 日前の日付を出す。
2. **並列調査**: general-purpose agent を 4 本並列起動する (①Claude Code/Anthropic ②OpenAI/Codex ③xAI/Grok ④その他 coding agent・モデル・画像・動画)。ソース一覧・取得方法・403 の fallback は [references/sources.md](references/sources.md) を読んで各 agent のプロンプトへ反映する。各 agent には「fetch した内容のみ報告」「取得失敗・制限を必ず報告」を課す。
3. **X 検索**: grok CLI で開発者事例 (オーケストレーション / hooks・skills / grok CLI 実践 / 日本) を収集する。実行方法は references/sources.md の grok CLI 節。
4. **ローカル実測**: `scripts/scan_transcripts.py --days 7` を実行し、references/output-contract.md の静的チェック一覧を実施する。dotfiles を重点、他リポジトリは全般傾向のみ。credential 類の走査が権限拒否されたら回避せず「手元確認を推奨」として記録する。
5. **レポート生成**: 下の構成規則で report.html / report.md / actions.md を書く。図解・タイルを作る前に dataviz スキルを読み込み、検証済みパレットを使う。
6. **記録と表示**: runs.jsonl に 1 行追記し、report.html をブラウザで開く。

## レポート構成規則

- セクション構成: タイムライン / Claude Code / Codex / xAI / その他 coding agent / モデル・フレームワーク / 画像・動画 / 押さえどころ (あなた向け) / X 事例 + ブログ定点観測 / 取得失敗・制限。
- **他ツール比較はインライン**。各リリースカード内に「他ツール比較」ボックスを置き、独立の機能対応マップは作らない。
- 押さえどころは各項目に「刺さる理由 (1 行)」と「実測」を付け、実測に基づく判定 (今すぐ / 今週中 / 不要) を明示する。
- 二次ソース由来は「△ 二次ソース」と明記し、一次未検証の数値を断定しない。
- **取得失敗・制限は最終セクションに全件明記する** (サイレントで落とさない)。実測の範囲と除外も書く。

## 失敗時の記録

- どんな失敗でも **runs.jsonl への追記だけは必ず行う** (status: success / partial / failed)。
- 部分失敗 (一部ソース 403、grok 実行不可など): レポートは生成し、制限セクションと runs.jsonl の failures に列挙する。
- 全滅 (レポート生成不能): `news/agent-weekly/<date>/FAILED.md` にエラー内容と再実行手順を書き、runs.jsonl に status: failed で追記する。

## やらないこと (人間判断の境界)

- issue / PR の作成。押さえどころの採用可否は人間が actions.md のチェックボックスで判断し、実装は別フローが行う。
- 設定ファイルの変更、ツール・skill の導入。
- news/agent-weekly/ 配下の git commit。private リポジトリで履歴に残したい場合は、呼び出し側プロンプトで明示的に指示する (手動の試し実行で commit が走らないようにするため)。
