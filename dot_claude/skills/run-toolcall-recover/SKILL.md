---
name: run-toolcall-recover
description: 出力に court / invoke / parameter などの生のツール呼び出しマークアップが地の文へ漏れている、ツール結果が文字化けしている、「malformed tool call」が繰り返される、といった出力崩壊・文脈汚染の兆候が出たときに発動。クリーンに実行できるまで粘って復旧し、原因と効いた手を notes.md に記録する。スキル/フックの改善は run-toolcall-improve が別途担う。
user-invocable: true
allowed-tools: Bash, Read, Write, Edit
---

# run-toolcall-recover — 出力崩壊からの復旧と記録

ツール結果の文字化け（環境障害）が文脈を汚染すると、次トークン生成が脱線して
**生のツール呼び出しマークアップ（`court` / invoke タグ / parameter タグ 等）が
地の文に漏れる**。本スキルの責務は2つだけ：

1. **正しく実行できるまで粘って復旧する**（行動規律）
2. **原因・効いた手を notes.md に記録する**（インシデント記録）

検知は `Stop`/`SubagentStop` hook（`~/.claude/hooks/detect-toolcall-leak.sh`）が担保する。
記録からのスキル/フック改善は **run-toolcall-improve** の責務であり、本スキルでは行わない
（復旧直後の汚染された文脈で本体を編集しないための分離）。

## 症状（どれかが出たら発動）

- 返信本文に `court`、invoke タグ、parameter タグ、`<function_calls>` が**そのまま**現れる
- 「Your tool call was malformed and could not be parsed」が繰り返される
- ツール結果が文字化け・途中で途切れる・無関係なタグが混入する

## 最重要ルール

- **正しく出せるまで粘る**: 撤退・回数制限はしない。クリーンなツール呼び出しが通るまで、正規の function-call チャネルで出し直し続ける。
- **ユーザーに通知・謝罪しない**: 漏れの説明や謝罪でターンを消費しない。黙って直し、作業を前に進める。
- **invoke/parameter タグを手書きしない**: ツール呼び出しは必ず正規の function-call チャネルで。地の文にマークアップをテキストとして書かない。
- **化けた結果は文脈汚染と疑う**: ツール結果が文字化けしたら、その内容を根拠に推論を続けない。
- **連発しない**: 崩壊中は単一・最小のツール呼び出しで ground truth を取り直す。`cat`/大量出力は避ける（再汚染の元）。

## 復旧手順

1. **クリーンに出し直す**: 直前のツール呼び出しが malformed だったら、同じ呼び出しを正規 function-call 形式で（`court` や生タグを付けずに）もう一度出す。通るまで繰り返す。
2. **事実を取り直す**: 推論の前提が化けた結果に依存していたら、`grep` や 1ファイルの `Read` 等、単一・最小のクリーンな呼び出しで ground truth を確認する。
3. **前進**: クリーンな結果が取れたら通常作業へ戻る。中断した本来のタスクを続行する。
4. **記録**: 復旧したら **必ず `notes.md` に追記**する（下記）。

## 記録（notes.md）

復旧のたびに `~/.claude/skills/run-toolcall-recover/notes.md` へ1件追記する：

- **日付** / **何で止まったか（症状・トリガ）** / **推定原因** / **何で直ったか（効いた手）** / **新たに分かった予防策**

記録はここまで。**この場で SKILL.md や hook を編集しない**。
繰り返しパターンの抽出と本体更新は、復旧が落ち着いた後（クリーンな文脈）で
run-toolcall-improve を起動して行う。

## hook との関係

- `Stop`/`SubagentStop` hook が最終メッセージ内の生マークアップ（invoke と parameter タグの共起など）を検出し `block` して再生成を強制する。クリーンになるまで何度でも block する（撤退しない）。
- hook 自身がエラー/判定不能なとき（jq 不在・transcript 不読）だけ fail open（exit 0）。
- 誤検知回避のためコードフェンス内の言及は除外している。

## Gotchas

- このスキルや notes.md で invoke/parameter タグを**例示**するときは必ずコードフェンス内に置く（hook の誤検知回避）。
- 根本原因は環境側のツール結果文字化け。スキル/hook は被害抑制であり、化け自体は防げない。
- 「化けたから」と同じコマンドを盲目的に連打しない。1回化けたら出力を確認してから次の単一呼び出しへ。
- 復旧直後の文脈は汚染されている前提。SKILL.md/hook の編集をその場でやらない（run-toolcall-improve に回す）。

## Files in this skill

- `notes.md` — 崩壊インシデントの記録（症状・原因・効いた手・予防策）。復旧のたび追記する。教訓の本体反映と改善履歴の管理は run-toolcall-improve が行う

## Additional resources

- 検知 hook: `~/.claude/hooks/detect-toolcall-leak.sh`（`Stop`/`SubagentStop` に登録）
- 改善スキル: `~/.claude/skills/run-toolcall-improve/`（notes.md からパターン抽出 → サブエージェントで本体更新）
