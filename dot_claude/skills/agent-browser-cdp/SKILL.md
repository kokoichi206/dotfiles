---
name: agent-browser-cdp
description: >
  agent-browser + CDP でログイン済み Chrome プロファイルを使ったブラウザ自動化。
  ページ操作、DOM 読み取り、内部 API 発見、Network 監視、スクリーンショット等が可能。
  トリガー: ブラウザ操作, agent-browser, CDP, サイト調査, DOM取得, ページ読み取り,
  Webサイトのデータ取得, ログイン済みサイトの操作, SPA判定, 内部API調査,
  ネットワーク監視, スクレイピング, ブラウザでログイン済みのサービスを操作
---

# agent-browser + CDP ブラウザ自動化

`npx agent-browser` CLI + Chrome DevTools Protocol (CDP) で、ログイン済み Chrome プロファイルのセッションを使ってブラウザを自動操作する。

## セットアップ

### Step 1: Chrome を CDP 付きで起動

ユーザーの Chrome を一度閉じてから実行（プロファイルのコピーを作るため、元の Chrome には影響しない）:

```bash
bash ~/.claude/skills/agent-browser-cdp/scripts/start-chrome-cdp.sh "Profile 1" 9222
```

- 第1引数: Chrome プロファイル名（`ls ~/Library/Application\ Support/Google/Chrome/` で確認）
- 第2引数: CDP ポート番号（デフォルト 9222）
- 仕組み: プロファイルを `/tmp/chrome-cdp-data-{port}/` にコピーし、CDP 付きで Chrome を起動

### Step 2: agent-browser から接続

```bash
npx agent-browser connect 9222
```

以降 `npx agent-browser <command>` で操作可能。Cookie が有効なのでログイン済みのサイトにそのままアクセスできる。

## 基本ワークフロー

```bash
npx agent-browser open "https://app.slack.com/client"  # ページを開く
npx agent-browser snapshot                              # 要素一覧（ref 付き）
npx agent-browser click @e42                            # ref で要素をクリック
npx agent-browser eval "document.title"                 # JS 実行
npx agent-browser screenshot /tmp/page.png              # スクリーンショット
```

## 注意点

- `eval` の JS は `(() => { ... })()` でラップすること（変数衝突回避）
- `snapshot` の ref はページ遷移・DOM 変更で変わる。操作前に毎回取得すること
- プロファイルの**コピー**なので元 Chrome とは独立。元でのログアウト等は反映されない
- 終了: `npx agent-browser close --all` または `pkill -f "remote-debugging-port"`

## リファレンス

- 全コマンド一覧: [references/commands.md](references/commands.md)
- パターン集（内部 API 発見、DOM 抽出、Network 監視、Slack 読み取り等）: [references/patterns.md](references/patterns.md)
