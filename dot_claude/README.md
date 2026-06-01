# Claude Code Configuration

Claude Code の設定を dotfiles で管理するためのディレクトリ。

## 構成

```
dot_claude/
├── CLAUDE.md                 # グローバルインストラクション
├── settings.json             # Claude Code 設定
├── hooks/                    # フック（Stop, Notification等）
├── commands/                 # カスタムコマンド
├── skills/                   # カスタムスキル（自作）
│   ├── typescript-strict/   # TypeScript strict mode パターン
│   ├── refactoring/         # リファクタリング原則
│   └── testing/             # テストパターン
├── marketplace-plugins.txt   # インストールするプラグインのリスト
├── marketplace-skills.txt    # マーケットプレイスからインストールするスキルのリスト
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

## スキルの管理

### スキルの種類

スキルは2種類に分けて管理します：

### 1. カスタムスキル（`skills/` ディレクトリ）

自作のスキルは `dot_claude/skills/` で管理し、`~/.claude/skills/` にシンボリックリンクを作成します。

- ✅ バージョン管理される
- ✅ 自由に編集できる
- ✅ 他のマシンと同期される

**追加方法**:
```bash
mkdir -p dot_claude/skills/your-skill
cat > dot_claude/skills/your-skill/SKILL.md <<'EOF'
---
name: your-skill
description: スキルの説明
---
# Your Skill
...
EOF
```

### 2. マーケットプレイススキル（`marketplace-skills.txt`）

マーケットプレイスからインストールしたスキルはリストのみ管理し、実体は自動更新されます。

- ✅ 自動更新が有効
- ✅ インストールリストで管理
- ❌ 直接編集しない（上流の更新が反映されなくなる）

**追加方法**:
```bash
echo "skill-name@marketplace-name" >> dot_claude/marketplace-skills.txt
./setup-claude.sh
```

### スキル追加の実際のフロー

新しいスキルを作成する際の推奨ワークフロー：

#### 1. まず ~/.claude/skills/ で直接作って試す

```bash
# 試験的にスキルを作成（エイリアス使用）
claude-skill-try my-new-skill

# または手動で
mkdir -p ~/.claude/skills/my-new-skill
vim ~/.claude/skills/my-new-skill/SKILL.md
```

この段階では：
- マーケットプレイスのスキルと同じ場所（`~/.claude/skills/`）
- すぐに Claude Code から使える
- 気軽に試行錯誤できる
- dotfiles にはまだ含まれない（一時的）

#### 2. 使ってみて良ければ dotfiles に「昇格」

スキルが有用だと判断したら dotfiles に移動して永続化：

```bash
# エイリアス使用（推奨）
claude-skill-promote my-new-skill

# または手動で
mv ~/.claude/skills/my-new-skill ~/ghq/github.com/kokoichi206/dotfiles/dot_claude/skills/
ln -sf ~/ghq/github.com/kokoichi206/dotfiles/dot_claude/skills/my-new-skill ~/.claude/skills/my-new-skill

# dotfiles にコミット
cd ~/ghq/github.com/kokoichi206/dotfiles
git add dot_claude/skills/my-new-skill
git commit -m "Add my-new-skill"
```

#### 3. 別のマシンでは setup-claude.sh で自動セットアップ

新しいマシンでは：

```bash
./setup-claude.sh
```

これで dotfiles 管理されたスキルが自動的に symlink される。

---

**ポイント**:
- 💡 試す段階では dotfiles 外で作成（気軽に削除できる）
- ✅ 良いと判断してから dotfiles に昇格（永続化）
- 🔄 別のマシンでは自動セットアップ

## Codex CLI のカスタムスキル

Codex CLI 用の自作スキルは `dot_codex/skills/` で管理されます。
→ `dot_codex/README.md` を参照してください。

## 手動インストール

個別にプラグイン/スキルをインストールする場合：

```bash
# プラグイン
claude plugin install kk-dev@cc-plugins

# スキル
claude skill install ui-ux-pro-max@ui-ux-pro-max-skill
```
