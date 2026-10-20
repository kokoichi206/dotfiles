# Codex CLI Configuration

Codex CLI (OpenAI Codex) の設定を dotfiles で管理するためのディレクトリ。

## 構成

```text
dot_codex/
├── AGENTS.md             # エージェントインストラクション
├── skills/               # カスタムスキル
├── config.common.toml    # Git で管理する共通設定
├── apply_config.py       # 共通設定の反映
└── test_apply_config.py  # マージ処理の検査
```

## セットアップと更新

`uv` が必要です。`tomlkit` はバージョンを固定し、`uv run` で取得します。

```bash
make codex-check  # 共通設定に未反映の変更があれば終了コード 1
make codex-apply  # 共通設定を反映
make test-codex-config
```

初回は `~/.codex/config.toml` を作成します。既存ファイルがあれば、共通設定に書いたキーを再帰的に上書きし、それ以外の設定とコメントを残します。配列は全体を置き換えます。変更がある場合だけバックアップを同じディレクトリに作り、実ファイルをパーミッション `0600` で置き換えます。symlink は作りません。既存の symlink への反映はエラーになります。

反映先は `CODEX_HOME` が設定されていれば `$CODEX_HOME/config.toml`、なければ `~/.codex/config.toml` です。反映後は Codex を再起動してください。`./setup-claude.sh` による初回セットアップでも共通設定を反映します。

## 共通設定とローカル設定

`config.common.toml` にはモデル・応答設定と、マシン間で共有する MCP の起動定義を置きます。認証情報、アカウント、絶対パス、プロジェクトの `trust_level`、アプリが追加する設定は、反映先の `config.toml` で管理します。実ファイルを丸ごと dotfiles に取り込む操作は用意していません。

AWS MCP の接続先と操作対象リージョンは `ap-northeast-1`、起動オプションは `--read-only` です。プロファイルは各マシンの `config.toml` に指定します。

```toml
[mcp_servers.aws_mcp.env]
AWS_PROFILE = "your-profile"
```

共通設定にあるキーをローカルで変更しても、次回の `make codex-apply` で共通設定の値に戻ります。共通ファイルからキーを削除しても、反映先のキーは削除しません。MCP サーバーの廃止・改名時は、反映先からも旧定義を削除してください。

`config.common.toml` と `config.local.toml` は Codex の自動読み込み対象としては使いません。この仕組みは共通設定を実際の `config.toml` へマージします。以前のセットアップが作った `config.local.toml` は、この処理では読み込みません。必要な設定は `config.toml` に移してください。

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
