---
name: search-past-sessions
description: 過去の Claude Code セッションをキーワード検索し、resume コマンドを提示する。トリガー - 前のセッション, 〜してたセッション探して, resume したい, あの続き, セッションなかったっけ, 前にやってたやつ
---

# 過去セッション検索 + resume

「前に〜してたセッション」をキーワードで探し、日時・冒頭プロンプト・プロジェクトを一覧化して、
resume コマンドまで提示する。

## セッションログの構造

- 置き場所: `~/.claude/projects/<encoded-path>/<session-id>.jsonl`
  - `<encoded-path>` はプロジェクト絶対パスの `/` と `.` を `-` に置換したもの
    （例: `-Users-kokoichi206-ghq-github-com-kokoichi206-dotfiles`）。
  - `<session-id>` は jsonl のファイル名（拡張子除く）で、そのまま resume に使える。
- 1 行 1 JSON。人間の発話は `.type == "user"` の `.message.content`。
  `content` は string または block 配列で、配列のときは `.type == "text"` の要素だけが発話
  （`tool_result` block は人間発話ではない）。
- **`<project>/<session-id>/subagents/` 配下の jsonl はサブエージェントのログなので検索対象から除外する。**
  glob をトップレベル（`~/.claude/projects/*/*.jsonl`）に限定すれば自然に除外される。

## 手順

1. **キーワードで検索する**
   - ユーザーの発話から検索語を決める（日本語・英語両方でヒットしうるので、固有名詞があればそれを優先する）。

     ```bash
     rg -l -i '<keyword>' ~/.claude/projects/*/*.jsonl
     ```

   - ヒットが多すぎる場合はキーワードを足す、期間で絞る（`ls -t` や `find -newermt`）などで数件に絞る。

2. **ヒットしたセッションの概要を取る**
   - 各ファイルについて、開始日時と冒頭の人間プロンプトを抽出する。

     ```bash
     # 開始日時
     jq -r 'select(.timestamp) | .timestamp' <file> | head -1

     # 冒頭の人間プロンプト（1 件目）
     jq -r 'select(.type == "user" and ((.isSidechain // false) | not))
            | .message.content
            | if type == "string" then . else (map(select(.type == "text") | .text) | join(" ")) end
            | select(length > 0)' <file> | head -5
     ```

3. **一覧化して提示する**
   - 「日時 / プロジェクト（encoded-path を復元したパス） / 冒頭プロンプトの要約 / session-id」の形で列挙し、
     どれが探していたものか特定できる情報を出す。

4. **resume コマンドを提示する**
   - resume は **そのセッションのプロジェクトディレクトリで実行する**。

     ```bash
     cd <プロジェクトパス>
     claude --resume <session-id>
     ```

   - 候補が 1 つに絞れないときは、上の一覧を提示してユーザーに選んでもらう。
