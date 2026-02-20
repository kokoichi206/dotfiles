# Codex CLI Configuration

Codex CLI (OpenAI Codex) の設定を dotfiles で管理するためのディレクトリ。

## 構成

```
dot_codex/
├── AGENTS.md             # エージェントインストラクション
├── skills/               # カスタムスキル（自作）
├── rules/                # コマンド許可ルール
├── config.common.toml    # 共通設定（全マシン共通）
└── .gitignore           # 除外設定
```

## セットアップ

新しいマシンで環境を再現する場合：

```bash
./setup-claude.sh
```

このスクリプトは以下を実行します：

1. `~/.codex/` へのシンボリックリンク作成
2. `config.common.toml` から `config.toml` を作成（初回のみ）
3. `config.local.toml` のテンプレート作成

## 設定ファイルの管理

### config.common.toml（共有）

全マシンで共通の設定：

- モデル設定
- パーソナリティ
- MCP サーバー設定
- TUI 設定

### config.local.toml（ローカル）

マシン固有の設定（`.gitignore` に含まれる）：

- プロジェクトの trust_level
- ローカル固有のパス設定

```toml
# 例: ~/.codex/config.local.toml
[projects."/path/to/your/project"]
trust_level = "trusted"
```

### 設定の適用順序

1. `config.common.toml`（共通設定）
2. `config.local.toml`（ローカル設定で上書き）

## カスタムスキル

自作のスキルは `skills/` ディレクトリで管理されます。

```
skills/
├── twada-tdd/
│   └── SKILL.md
├── dotfiles-survey/
│   └── SKILL.md
└── .system/
    └── SKILL.md
```

新しいスキルを追加した場合、dotfiles に含めてコミットしてください。

## コマンド許可ルール

`rules/default.rules` でコマンドの許可ルールを管理します。

```
prefix_rule(pattern=["gh", "pr", "view"], decision="allow")
prefix_rule(pattern=["rm", "-rf", "specific-dir"], decision="allow")
```
