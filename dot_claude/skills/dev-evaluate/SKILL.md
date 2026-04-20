---
name: dev-evaluate
description: |
  実装変更を 3 層スコアリング（Hard Gate + Deterministic + LLM-as-judge）で評価するステージスキル。
  dev-loop オーケストレーターから code-review Agent として呼び出される。
  実装の経緯を知らない状態で、成果物だけを見て評価する。
visibility: public
---

# Dev Evaluate - 3 層スコアリング評価ステージ

実装変更を、実装の経緯を一切知らない状態で評価する。
**決定論的判定を最大化し、LLM 判定の比重を下げる** ことで評価ゲーミングを防ぐ。

## 入力

- オーケストレーターから渡される `task_dir` と `iteration`（例: `task_dir=.dev-loop/20260419-103000-add-auth-feature/`, `iteration=002`）
- `<task_dir>/plan.md`: 実装計画（タスクタイプ・受け入れ条件を含む）
- `<task_dir>/acceptance-tests/`: 受け入れテストファイル
- `<task_dir>/acceptance-hash.txt`: 受け入れテストのハッシュ
- `<task_dir>/ui-checks.yaml`（UI タスクの場合）
- `git diff` の結果
- `references/eval-criteria.md`: 3 層スコアリングの基本ルール
- `references/task-types.md`: タスクタイプ別の Layer 2 配点
- `references/ui-heuristics.md`: UI Layer 3 チェックリスト
- `references/common-heuristics.md`: 非 UI Layer 3 チェックリスト

## パス規約

本ドキュメントで `<task_dir>` はオーケストレーターから渡されたタスクディレクトリ。
レポートの書き出し先は `<task_dir>/iterations/iteration-NNN/eval-report.md`。

## 手順

### 1. 前提確認

1. `<task_dir>/plan.md` を読む
2. `task_type` を取得する（backend / ui-new / ui-change / refactor / bugfix）
3. 受け入れ条件を取得する

### 2. Layer 1: Hard Gate

**受け入れテストを実行する前に、ハッシュを検証する。**

```bash
# 現在の受け入れテストのハッシュを計算
find <task_dir>/acceptance-tests -type f \( -name "*.test.*" -o -name "*_test.*" -o -name "*.spec.*" \) \
  | sort | xargs md5 | md5
```

`<task_dir>/acceptance-hash.txt` の値と比較する。

- **ハッシュ不一致 → 0 点、以降スキップ**
- **ハッシュ一致 → 受け入れテストを実行**

受け入れテスト実行:

```bash
# プロジェクトのテストコマンドで <task_dir>/acceptance-tests/ を対象に実行
```

- **全件 PASS → 60 点付与、Layer 2 へ**
- **1 件でも FAIL → 0 点、以降スキップ（失敗したテスト名を記録）**

### 3. Layer 2: Deterministic Quality (30 点)

`task-types.md` の task_type 別配点に従って測定する。

全タスク共通:

#### 3a. テスト実行

```bash
# 全テスト実行
```

記録: PASS 数 / 総数、実行時間

#### 3b. 型チェック

```bash
# 例: tsc --noEmit, mypy
```

記録: エラー数、警告数

#### 3c. Lint

```bash
# 例: eslint, ruff, clippy
```

記録: エラー数、警告数

#### 3d. ビルド

```bash
# 例: npm run build, cargo build
```

記録: exit code、ビルド時間

#### 3e. UI タスク追加項目（task_type が ui-* の場合）

```bash
# E2E テスト
npx playwright test

# Lighthouse
npx lhci autorun

# axe-core
npx @axe-core/cli <URL>

# Visual regression
npx playwright test --config=visual.config.ts

# <task_dir>/ui-checks.yaml の deterministic コマンド群を実行
```

#### 3f. スコア計算

task-types.md の配点表に従って集計する。
測定できなかった項目はレポートに「N/A」と明記し、他の項目で按分する。

### 4. Layer 3: LLM-as-judge (10 点)

該当するチェックリストを読む:

- UI タスク: `references/ui-heuristics.md` + `<task_dir>/ui-checks.yaml` の `heuristic_checklist`
- 非 UI タスク: `references/common-heuristics.md` の task_type セクション

**各項目を pass / fail で判定する:**

- 差分と関連コード（Read で取得）に基づいて判定する
- 検証不能な項目（そのタスクで対象外）は `N/A` として総数から除外する
- 自由記述で「全体的に良い」のような評価は禁止

スコア計算:

```
layer3_score = 10 × (passed / (total - n_a))
```

### 5. 指摘の分類

各 fail 項目および追加の所見を以下に分類する:

- **[修正可能]**: 次のイテレーションで直接修正できる
- **[修正不可能]**: 現在の制約では修正不能（理由を明記）
- **[設計起因]**: 計画・アーキテクチャの見直しが必要

### 6. レポート作成

`<task_dir>/iterations/iteration-NNN/eval-report.md` に以下の形式で書き出す:

```markdown
# 評価レポート (Iteration NNN)

## Task Type
{backend / ui-new / ui-change / refactor / bugfix}

## Layer 1: Hard Gate
- ハッシュ検証: PASS / FAIL
- 受け入れテスト: PASS (X/Y) / FAIL
- 結果: **60 点 / 0 点**

{Layer 1 FAIL の場合、ここで終了}

## Layer 2: Deterministic Quality
| 項目 | 配点 | 測定値 | 獲得 |
|---|---|---|---|
| 全テストパス率 | 10 | X/Y | X |
| 型チェック | 10 | エラー N | X |
| ビルド | 5 | PASS/FAIL | X |
| カバレッジ | 5 | XX% | X |
| ... | | | |
| **合計** | **30** | | **X** |

## Layer 3: LLM-as-judge
チェックリスト種別: {ui-heuristics / common-heuristics}
pass: X / fail: Y / N/A: Z
**layer3_score: XX / 10**

### Failed items
- [項目名]: 失敗理由

## 合計スコア: XX / 100

## 指摘一覧

### [修正可能]
- 指摘内容と改善案（具体的なファイル/行番号つき）

### [修正不可能]
- 指摘内容と理由

### [設計起因]
- 指摘内容と影響範囲

## 総評
（全体的な品質評価と改善の方向性）
```

## 制約

- **Edit を使わない**: 判定のみ。コードの修正は行わない
- **受け入れテストを変更しない**: ハッシュ検証の対象
- **実装の経緯に言及しない**: 会話履歴がないため、推測で経緯を語らない
- **測定を飛ばさない**: 「たぶん通る」ではなく、必ず実行して結果を記録する
- **自由記述スコアをしない**: Layer 3 は構造化チェックリストの pass/fail のみ

## 出力

- `<task_dir>/iterations/iteration-NNN/eval-report.md`

## 参考資料

- `references/eval-criteria.md`: 3 層スコアリングの基本ルール
- `references/task-types.md`: タスクタイプ別の Layer 2 配点
- `references/ui-heuristics.md`: UI タスクの Layer 3 チェックリスト
- `references/common-heuristics.md`: 非 UI タスクの Layer 3 チェックリスト
