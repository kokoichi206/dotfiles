---
name: audit-sessions
description: 過去の Claude Code セッションログから人間発話を抽出し、スキル化候補・ルール化候補・プロンプト改善の 3 カテゴリで並列分析する監査手順。トリガー - セッションログ監査, 過去のログを見て改善点, スキル化した方がいいもの探して, ハーネス監査, プロンプト傾向分析
---

# セッションログ監査

一定期間のセッションログから人間の発話だけを抽出し、
「繰り返し手打ちしている定型手順」「毎回口頭で補っているルール」「プロンプトの書き方の癖」を洗い出す。
出力カテゴリは 3 つに固定する: **スキル化候補 / ルール化候補 / プロンプト改善**。

## 手順

### 1. 対象セッションを列挙する

- セッション jsonl は `~/.claude/projects/<encoded-path>/<session-id>.jsonl`
  （`<encoded-path>` はプロジェクト絶対パスの `/` と `.` を `-` に置換したもの）。
- **`<project>/<session-id>/subagents/` 配下はサブエージェントのログなので除外する。**
  `-maxdepth 2` で glob をトップレベルに限定すれば除外できる。

```bash
find ~/.claude/projects -maxdepth 2 -name '*.jsonl' \
  -newermt '<開始日>' ! -newermt '<終了日>' | sort
```

### 2. 人間発話のみを抽出する

- 抽出条件: `.type == "user"` かつ sidechain でない。
  `content` は string または block 配列（配列は `.type == "text"` のみ採用。`tool_result` は除外される）。
- ノイズ除去: スキル展開（`<command-name>` / `<local-command-stdout>`）、`Caveat:` で始まる注記、
  `<system-reminder>` ブロックを除去する。
- 1 発話 600 字に切り詰める（長大な diff 貼り付け等で分析用コーパスが溢れるのを防ぐ）。

```bash
jq -r '
  select(.type == "user" and ((.isSidechain // false) | not))
  | .message.content
  | if type == "string" then . else (map(select(.type == "text") | .text // empty) | join("\n")) end
  | select(length > 0)
  | select(startswith("Caveat:") | not)
  | gsub("<system-reminder>[\\s\\S]*?</system-reminder>"; "")
  | select(test("<command-name>|<local-command-stdout>") | not)
  | gsub("^\\s+|\\s+$"; "")
  | select(length > 0)
  | .[0:600] + "\n---"
' <file>.jsonl
```

- ファイルごとにヘッダ（プロジェクト名・session-id・日付）を付けて 1 コーパスに連結する。

### 3. バケットに分割する

- プロジェクト単位でグルーピングし、量が偏らないよう数バケットに分割する
  （関連プロジェクトは同じバケットに入れると文脈横断のパターンを拾いやすい）。

### 4. バケットごとに並列エージェントで分析する

- 各エージェントへの指示に含めること:
  - 出力カテゴリを固定する: **スキル化候補 / ルール化候補 / プロンプト改善** の 3 つ。
  - 各候補に **出現回数** と **代表発話の引用（1〜2 個、原文まま）** を必ず付ける。
    引用のない候補は採用しない（後から検証できないため）。
  - 1 回しか出ていないものは「候補」ではなく「観察」として分ける。

### 5. 統合して報告する

- バケット横断で同一パターンをマージし、出現回数を合算する。
- **過去監査の結論をメモリ（`~/.claude/projects/<project>/memory/MEMORY.md` と配下のノート）から読み、
  既知事項・対応済み事項を除外する。** 報告するのは新規の発見のみ。
- 各候補に「次のアクション」（スキル名案・ルール文案・確認事項）を 1 つ添えて提示する。
  スキル / ルールの作成自体はユーザーの承認を得てから行う。
