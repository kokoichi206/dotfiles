---
paths:
  - "**/.claude/skills/**"
  - "**/dot_claude/skills/**"
  - "**/.claude/commands/**"
  - "**/dot_claude/commands/**"
---

# skill / command の置き場所・命名ガイド

skill / command を新規作成するときに、置き場所とスコープを次の決定木で決める。
「どこに入れるか」を毎回迷わないための基準。

## 置き場所（上から順に判定）

1. **秘密情報（メールアドレス / PII / 金額 / トークン等）を含むか**
   → private リポ（例: `private-files` / `tasks`）の `.claude/` に置く。
   **公開リポ（dotfiles）には置かない。** アドレス等は直書きせず、実行時に認証情報から導出する。
2. **複数リポ横断で使うか**
   → user スコープ（`dot_claude/skills/`。`setup-claude.sh` で `~/.claude/skills/` へ symlink される）。
3. **特定リポに閉じるか**
   → そのリポの `.claude/skills/`（または `.claude/commands/`）。

## 命名

- **kebab-case**、**動詞-目的語**、**後で思い出せる**名前にする。
  （`overdue-tasks` のような目的語先行の名前は、いざ叩くとき思い出せなかった実例がある。
  `next-todo` のように「何をするか」で引ける名前にする。）

## 補足

- そもそも rule（paths 注入 / 常時注入）にするか skill（オンデマンド）にするかの判断は
  `authoring-rules.md` の「発火頻度 × 常時コスト」基準に従う。
- 試作は `~/.claude/skills/` で作って試し、良ければ `dot_claude/skills/` へ昇格する
  （詳細は `dot_claude/README.md`）。
