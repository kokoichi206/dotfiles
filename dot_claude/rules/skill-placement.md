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

## 記載境界（SKILL.md に何を書くか）

- 書くのは「実行時に毎回必要な指示」だけ: 手順・判定基準・制約・落とし穴。
- 書かない:
  - 一回きりのセットアップ・登録手順（cron / Orca automation の登録、ツールの install 等）
    → 依頼されたときに組み立てる。スキル本文には持たせない
    （登録・セットアップ自体が仕事のスキルは例外。register-orca-automation 等）
  - 設定値・スケジュール・アドレス等の具体値の複製（変更に追従できず嘘になる）
  - コードや設定ファイルを読めば分かる説明
- 判定基準: 「このスキルを実行中のエージェントが、その行を読まないと失敗するか」。No なら書かない。

## 発火検証

- skill を作成・改名・description 変更したら、コミット前に発火検証をする。
  スキル名もトリガー語も含まない自然な依頼文をサブエージェントに投げ、
  対象 skill が自発的に呼ばれるかを確認する（発火の有無は使用スキルの報告で判定）。
- 「発火する発話例 / しない発話例」をユーザーへの報告に含める。
  不発なら description の「いつ使うか」とトリガー語彙を直してから再検証する。

## codex 同期

- user スコープ（`dot_claude/skills/`）に skill を作ったら、codex でも使うかをその場で判断する。
  使うなら `dot_codex/skills/` に相対 symlink を置く:
  `cd dot_codex/skills && ln -s ../../dot_claude/skills/<name> <name>`
- Claude 専用機能（Skill ツール・Agent 呼び出し等）に依存しない書き方なら codex でもそのまま動く。

## 補足

- そもそも rule（paths 注入 / 常時注入）にするか skill（オンデマンド）にするかの判断は
  `authoring-rules.md` の「発火頻度 × 常時コスト」基準に従う。
- 試作は `~/.claude/skills/` で作って試し、良ければ `dot_claude/skills/` へ昇格する
  （詳細は `dot_claude/README.md`）。
