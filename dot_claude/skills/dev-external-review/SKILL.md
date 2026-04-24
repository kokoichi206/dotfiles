---
name: dev-external-review
description: |
  Codex CLI（GPT）を使って、異なるモデルの視点から実装をレビューするステージスキル。
  dev-loop オーケストレーターから呼び出される。Codex 不在時は Claude subagent で代替。
visibility: public
---

# Dev External Review - 外部レビューステージ

異なるモデル（GPT）の視点から実装をレビューする。
Claude の Evaluate とは異なるバイアスで多角的に検証することが目的。

## 入力

- オーケストレーターから渡される `task_dir` と `iteration`
- `<task_dir>/plan.md`: 実装計画
- `git diff`: 変更差分

## パス規約

本ドキュメントで `<task_dir>` はオーケストレーターから渡されたタスクディレクトリ。
レポートの書き出し先は `<task_dir>/iterations/iteration-NNN/external-review.md`。

## 手順

### 方法 1: Codex CLI（推奨）

```bash
bash scripts/run_codex_review.sh "$(pwd)" "<task_dir>" "<iteration>"
```

引数:
- 第 1 引数: プロジェクトルート（通常 `$(pwd)`）
- 第 2 引数: task_dir（例: `.dev-loop/20260419-103000-add-auth-feature/`）
- 第 3 引数: iteration（例: `002`）

スクリプトが以下を行う:
1. git diff で変更差分を取得
2. `<task_dir>/plan.md` の計画を読み込み
3. Codex CLI でレビューを実行
4. 結果を `<task_dir>/iterations/iteration-NNN/external-review.md` に保存

### 方法 2: Claude subagent（Codex 不在時）

Codex が利用できない場合、Claude 側の code-review subagent で代替する。
ただし dev-external-review 自身はこの subagent を起動できない（Agent tool 非付与）。
その場合は結果ファイルに「Codex 不在のため外部レビュー未実行」と記載し、
オーケストレーターに通知する（オーケストレーター側で Stage 3 の dev-evaluate とは別インスタンスの code-review を起動する運用）。

書き出し先:

```
<task_dir>/iterations/iteration-NNN/external-review.md
```

## 出力

- `<task_dir>/iterations/iteration-NNN/external-review.md`

## スクリプト

- `scripts/run_codex_review.sh`: Codex CLI 実行スクリプト
