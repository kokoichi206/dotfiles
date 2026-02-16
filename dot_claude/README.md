# Claude Code Configuration

Claude Code の設定を dotfiles で管理するためのディレクトリ。

## 構成

```
dot_claude/
├── CLAUDE.md                 # グローバルインストラクション
├── settings.json             # Claude Code 設定
├── hooks/                    # フック（Stop, Notification等）
├── commands/                 # カスタムコマンド
├── marketplace-plugins.txt   # インストールするプラグインのリスト
├── marketplace-skills.txt    # インストールするスキルのリスト
└── .gitignore               # 除外設定
```

## セットアップ

新しいマシンで環境を再現する場合：

```bash
./setup-claude.sh
```

このスクリプトは以下を実行します：

1. `~/.claude/` へのシンボリックリンク作成
2. マーケットプレイスプラグインのインストール
3. マーケットプレイススキルのインストール

## マーケットプレイスの管理

### プラグイン

マーケットプレイスからインストールしたプラグインは実体を含めず、リストのみ管理します。

- 追加: `marketplace-plugins.txt` に追記
- インストール: セットアップスクリプトが自動実行
- 更新: `claude plugin update <plugin-name>` で自動更新

### スキル

同様にスキルもリストのみ管理します。

- 追加: `marketplace-skills.txt` に追記
- インストール: セットアップスクリプトが自動実行
- 更新: マーケットプレイスが自動更新

## カスタムスキル

自作のスキルは `~/.codex/skills/` で管理されます。
→ `dot_codex/` を参照してください。

## 手動インストール

個別にプラグイン/スキルをインストールする場合：

```bash
# プラグイン
claude plugin install ww@cc-plugins

# スキル
claude skill install ui-ux-pro-max@ui-ux-pro-max-skill
```
