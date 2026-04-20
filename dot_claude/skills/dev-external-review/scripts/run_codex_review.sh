#!/usr/bin/env bash
set -euo pipefail

# Dev Loop: Codex CLI による外部レビュー
# Usage: run_codex_review.sh <project_dir> <task_dir> <iteration>
#   project_dir: プロジェクトのルートディレクトリ（通常 $(pwd)）
#   task_dir:    タスクディレクトリ（例: .dev-loop/20260419-103000-add-auth-feature）
#   iteration:   イテレーション番号 3 桁（例: 002）

PROJECT_DIR="${1:-$(pwd)}"
TASK_DIR="${2:?task_dir is required}"
ITERATION="${3:?iteration is required (3 digits)}"

OUTPUT_DIR="${TASK_DIR}/iterations/iteration-${ITERATION}"
OUTPUT_FILE="${OUTPUT_DIR}/external-review.md"

mkdir -p "$OUTPUT_DIR"

# codex が利用可能か確認
if ! command -v codex &>/dev/null; then
  echo "codex CLI が見つかりません。Claude Code subagent でのレビューにフォールバックしてください。" > "$OUTPUT_FILE"
  exit 1
fi

# 差分を取得（未コミット → ステージ → ブランチ差分の順で試行）
DIFF=""
DIFF=$(git diff HEAD 2>/dev/null || true)
if [ -z "$DIFF" ]; then
  DIFF=$(git diff --cached 2>/dev/null || true)
fi
if [ -z "$DIFF" ]; then
  DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
  DIFF=$(git diff "${DEFAULT_BRANCH}...HEAD" 2>/dev/null || true)
fi

if [ -z "$DIFF" ]; then
  echo "レビュー対象の差分がありません。" > "$OUTPUT_FILE"
  exit 0
fi

# 計画を読み込む
PLAN="（計画ファイルなし）"
if [ -f "${TASK_DIR}/plan.md" ]; then
  PLAN=$(cat "${TASK_DIR}/plan.md")
fi

# 差分をファイルに保存（codex はパイプ非対応のためコマンド置換で渡す）
DIFF_FILE=$(mktemp /tmp/dev-loop-diff.XXXXXX)
echo "$DIFF" > "$DIFF_FILE"

codex exec --full-auto --sandbox read-only --cd "$PROJECT_DIR" "$(cat <<PROMPT
以下の変更差分をレビューしてください。

## 実装計画
${PLAN}

## 変更差分
$(cat "$DIFF_FILE")

## レビュー観点
1. 要件との整合性: 計画に書かれた要件を満たしているか
2. バグ・ロジックエラー: 明らかなバグや境界条件の見落とし
3. コード品質: 可読性、命名、不要な複雑さ
4. セキュリティ: インジェクション、認証漏れ、機密情報のハードコード
5. 不要な変更: スコープ外の変更が含まれていないか

## 出力形式
各指摘に以下の分類を付けてください:
- [修正可能]: 次のイテレーションで直接修正できる
- [修正不可能]: 現在の制約では修正不能（理由を明記）
- [設計起因]: 計画・アーキテクチャの見直しが必要

最後に 100 点満点でスコアを付けてください。

確認や質問は不要です。具体的な指摘と改善案まで自主的に出力してください。
PROMPT
)" > "$OUTPUT_FILE" 2>&1

rm -f "$DIFF_FILE"
