---
name: run-toolcall-improve
description: 「ハイジーン改善」「notes の教訓を反映して」と言われたとき、または出力崩壊からの復旧が落ち着いて run-toolcall-recover の notes.md に未反映のインシデント記録が溜まっているときに発動。
user-invocable: true
allowed-tools: Bash, Read, Write, Task
---

# run-toolcall-improve — 記録からの自己改善（recover とは分離）

run-toolcall-recover が notes.md に積んだインシデント記録を読み、
**繰り返しパターン・新しい検知署名・規律の穴**を抽出して本体（SKILL.md / hook）に反映する。

**形は orchestrated**: メイン文脈が手順1〜5（読込→抽出→委譲→検証→記録）を指揮する。
ファイル編集だけをサブエージェント（Task, general-purpose）に dispatch し、
検証と履歴記録はメインで行う。fork はしない。

**分離の理由**: 復旧直後の文脈は汚染されている可能性が高く、その場で本体を編集すると
編集自体が脱線・破壊のリスクを持つ。改善は必ず**クリーンな文脈で別途**起動し、
実際のファイル編集は**サブエージェントに委譲**してメイン文脈から隔離する。

## 対象ファイル（これ以外に触れない）

- `~/.claude/skills/run-toolcall-recover/SKILL.md` — 復旧の行動規律
- `~/.claude/skills/run-toolcall-recover/notes.md` — インシデント記録（読み取りのみ）
- `~/.claude/hooks/detect-toolcall-leak.sh` — 検知署名・block ロジック
- `~/.claude/hooks/detect-toolcall-leak.test.sh` — hook の回帰テスト（署名変更時にケース追加）
- `history.md`（このスキル内）— 改善履歴（読み取り＋追記）
- この SKILL.md 自身（手順の改善が必要なとき）

**変更対象は `~/.claude/` 配下のみ。`~/dev-flow-skills` には絶対に触れない。**

## 手順

### 1. 現状把握（メインで読むのはこの4ファイルだけ）

notes.md・recover の SKILL.md・hook・history.md を読み、記録と現行の規律/検知のギャップを見る。
history.md は反映済み事項の台帳。**既に反映済みの教訓を二重反映しない**。

### 2. パターン抽出

notes.md の記録を横断して以下を探す：

- **繰り返している症状・原因**（2回以上出たら規律 or 検知に昇格候補）
- **hook が拾えなかった漏れ署名**（新しい壊れ方のトークン・タグ変種）
- **効いた手のうち SKILL.md に未記載のもの**
- **誤検知・テスト時の罠**（hook のテスト手順に反映すべきもの）

抽出結果が空（既に全部反映済み）なら、**何も変更せず終了**してよい。無理に変更を作らない。

### 3. 更新をサブエージェントに委譲

Task tool（subagent_type: general-purpose）に、**具体的な編集指示**を渡して委譲する。
指示に必ず含めること：

- 対象ファイルの絶対パスと、変更内容（何をどこへ・なぜ）
- **制約**: invoke/parameter 等のタグ例示は必ずコードフェンス内に置く／hook の fail-open（jq 不在・transcript 不読時 exit 0）と「クリーンになるまで block し続ける（撤退なし）」の設計を壊さない／コードフェンス除外による誤検知回避を壊さない
- `~/dev-flow-skills` には触れないこと
- 完了後に変更点の要約を返すこと

### 4. 検証

サブエージェントの報告を鵜呑みにせず、メインで検証する：

- 変更ファイルを読み直し、意図どおりか確認（SKILL.md は整合性、hook は構文 `bash -n`）
- **hook を変更した場合は回帰テスト必須**（下記）

### 5. 改善履歴を記録

このスキルの `history.md` 末尾に「いつ・何を・なぜ更新したか」を1件追記する
（次回の手順1で二重反映を防ぐ台帳。notes.md には書かない — あちらは純インシデントログ）。

## hook の回帰テスト（テスト時の罠・必読）

既存の回帰テストスクリプト `~/.claude/hooks/detect-toolcall-leak.test.sh` をまず実行する
（6パターン: leak/clean/fenced/単独court/文中court/単独タグ）。署名を追加・変更したら
このスクリプトにケースを追加してから回す。

合成 transcript は **1行=1JSON の JSONL** で作る。過去の誤判定の記録より：

- `jq -n` は既定で複数行 pretty 出力になり transcript として解析されない → **必ず `jq -nc`**
- コードフェンスをバックスラッシュでエスケープすると実際の素の三連バックティックと変わり sed が一致しない → **テストデータは素のバックティックで作る**

テスト例（leak ケース。タグ文字列は変数経由で組み立てる）：

```bash
t=$(mktemp); tag='<invoke name="X"><parameter name="y">1</parameter></invoke>'
jq -nc --arg s "court $tag" '{type:"assistant",message:{content:[{type:"text",text:$s}]}}' > "$t"
echo "{\"transcript_path\":\"$t\"}" | ~/.claude/hooks/detect-toolcall-leak.sh
# 期待: {"decision":"block",...} が出力される。clean/fenced ケースでは何も出力されない。
```

## Gotchas

- このスキル自身の地の文にもタグを生で書かない。例示は常にコードフェンス内。
- 検知は積極的でよい（このユーザーの通常出力に該当トークンはまず出ない）。ただし署名追加時は fenced 除外との相互作用を必ずテストする。
- hook は「表示前」やターン途中の漏れは捕捉できない（Stop はターン末の網）。この限界を「直す」方向の変更は提案しない — 記録済みの設計上の確定事項（notes.md 2026-06-10）。

## Files in this skill

- `history.md` — 改善履歴の台帳（いつ・何を・なぜ反映したか）。手順1で読み、手順5で追記する

## Additional resources

- 復旧スキル: `~/.claude/skills/run-toolcall-recover/`（その場の復旧と notes.md 記録）
- 検知 hook: `~/.claude/hooks/detect-toolcall-leak.sh`
