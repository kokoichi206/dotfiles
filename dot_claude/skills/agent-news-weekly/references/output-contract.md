# 出力契約の詳細

issue 化フロー (別 skill) がこの形式を parse する。破壊的変更をしない。

## runs.jsonl

1 実行 = 1 行の JSON。追記のみ (上書き禁止)。

```json
{"date":"2026-07-20","status":"partial","report":"news/agent-weekly/2026-07-20/report.html","failures":["x.ai/news WebFetch 403 (WebSearch 代替)","レンダリング目視確認 未実施"],"notes":"補足があれば"}
```

- `status`: `success` (全ソース取得 + 実測完了) / `partial` (fallback 使用・一部欠落あり) / `failed` (レポート生成不能)
- `failures`: 空でも必ず配列で入れる。「何が・なぜ・どう代替したか」を 1 要素 1 行で
- `failed` の場合は `report` の代わりに `"failed_doc":"news/agent-weekly/<date>/FAILED.md"` を入れる

## actions.md

人間がチェックボックスで採用可否を判断し、issue 化フローはチェック済み (`[x]`) の行だけ拾う。

```markdown
# actions 2026-07-20

- [ ] `id:2026-07-20-a1` **今すぐ** permission 除外ルールの書き換え — Edit(!.git/**) 型を !**/.git/** 形へ (実測: hooks の if: は使用ゼロで無風、permission 側のみ該当)
- [ ] `id:2026-07-20-a2` **今週中** token-diet 導入 — SessionStart hook に節約ディレクティブ注入 (実測: 出力 42.4M tok/週)

## 対応不要 (記録のみ)

- subagent/WebSearch セッション上限: 実測最大が上限の 1/8 以下
```

- `id:` は `<date>-a<連番>` で一意。行内に 判定 (**今すぐ** / **今週中**)・タイトル・対応内容・実測根拠を収める (1 行 = 1 項目で parse 可能に)。
- 判定「不要」の項目はチェックボックスにせず「対応不要 (記録のみ)」節へ箇条書きで残す。

## report.md

report.html と同じセクション構成の markdown 版。ソース URL・X ポスト URL を保持する。HTML だけにしかない情報を作らない (diff・引用は md 側で行うため)。

## ローカル実測の静的チェック一覧

transcript 実測 (`scripts/scan_transcripts.py`) に加えて毎回行う:

- **hooks**: `dot_claude/settings.json` の hook エントリ (matcher / if:) を列挙し、当週のニュースにある構文・挙動変更と突き合わせる。
- **permission**: `dot_claude/settings.json`・`~/.claude/settings.json`・`.claude/settings.local.json` のルールを、当週の permission 系変更 (glob 解釈・警告対象など) と突き合わせる。
- **他ツールの利用実態**: `~/.codex` (config.toml の model・セッション数)、`~/.grok` (セッション時期は birth time で確認)、必要に応じ `~/.gemini` 等。ニュースが「使っているモデル・バージョン」に効くかを判定する。
- **制限の明記**: transcript 集計は `~/.claude/projects` 直下 1 階層・sidechain 除外・output_tokens 概算である旨を毎回レポートに書く。
- credential 類 (.env・鍵) の走査が権限拒否されたら回避せず、「手元確認を推奨」として actions.md とレポートに記録する。
