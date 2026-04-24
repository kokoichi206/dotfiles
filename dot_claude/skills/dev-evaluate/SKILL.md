---
name: dev-evaluate
description: |
  実装変更を 3 層スコアリング（Hard Gate + Deterministic + LLM-as-judge）で評価するステージスキル。
  dev-loop オーケストレーターから code-review Agent として呼び出される。
  scenarios.md（spec）のハッシュと scenario ↔ test の対応を検証する。
  実装の経緯を知らない状態で、成果物だけを見て評価する。
visibility: public
---

# Dev Evaluate - 3 層スコアリング評価ステージ

実装変更を、実装の経緯を一切知らない状態で評価する。
**決定論的判定を最大化し、LLM 判定の比重を下げる** ことで評価ゲーミングを防ぐ。

**重要な設計原則:**
- spec = `<task_dir>/scenarios.md`（ハッシュ検証）
- tests = `<task_dir>/acceptance-tests/`（シナリオ対応を検証）
- 両者の対応を機械的にチェックすることで「LLM が承認 scenario を省略」を防ぐ

## 入力

- オーケストレーターから渡される `task_dir` と `iteration`
- `<task_dir>/plan.md`: 実装計画
- `<task_dir>/scenarios.md`: 受け入れシナリオ（spec, ハッシュ保護）
- `<task_dir>/scenarios-hash.txt`: scenarios.md のハッシュ
- `<task_dir>/acceptance-tests/`: テスト（柔軟、検証対象）
- `<task_dir>/ui-checks.yaml`（UI タスクの場合）
- `git diff` の結果
- `references/eval-criteria.md`: 3 層スコアリングの基本ルール
- `references/task-types.md`: タスクタイプ別の Layer 2 配点
- `references/ui-heuristics.md`: UI Layer 3 チェックリスト
- `references/common-heuristics.md`: 非 UI Layer 3 チェックリスト

## 手順

### 1. 前提確認

1. `<task_dir>/plan.md` を読む
2. `<task_dir>/scenarios.md` を読む（シナリオ ID S1, S2, ... を把握）
3. `task_type` を取得
4. 受け入れ条件（各シナリオの Then）を把握

### 2. Layer 1: Hard Gate（3 段階判定）

Layer 1 は以下 3 つを全て満たしたら 60 点、いずれか 1 つでも失敗したら 0 点。

#### 2a. scenarios.md のハッシュ検証

**共有スクリプトを使う**:

```bash
bash dot_claude/skills/dev-loop/scripts/compute_scenarios_hash.sh <task_dir>/scenarios.md
```

`<task_dir>/scenarios-hash.txt` の値と比較する。

- **ハッシュ不一致 → 0 点、以降スキップ**

#### 2b. scenario ↔ test の対応チェック

scenarios.md の各シナリオ ID（S1, S2, ...）に対応するテストが存在するか検証。

```bash
# scenarios.md から ID を抽出
grep -oE '^## (S[0-9]+):' <task_dir>/scenarios.md \
  | grep -oE 'S[0-9]+' \
  | LC_ALL=C sort -u > /tmp/expected-scenarios.txt

# テストファイルから ID を抽出（Playwright / Jest / Vitest 共通: test('S1:...) や it('S1:...))
grep -rhoE "(test|it)\(['\"](S[0-9]+):" <task_dir>/acceptance-tests/ \
  | grep -oE 'S[0-9]+' \
  | LC_ALL=C sort -u > /tmp/actual-tests.txt

# 差分
diff /tmp/expected-scenarios.txt /tmp/actual-tests.txt
```

判定:
- 完全一致 → OK
- **不一致 → 0 点、以降スキップ**
  - 欠落しているシナリオ ID、または余分な ID を eval-report.md に記録

#### 2c. 受け入れテスト実行

plan.md の「Layer 2 検証コマンド」から受け入れテストコマンドを取得し、実行する:

```bash
# 例: npx playwright test <task_dir>/acceptance-tests/
```

判定:

| 実行結果 | 判定 | 点数 |
|---|---|---|
| 全件 PASS | PASS | Layer 1 通過 |
| 1 件でも FAIL | FAIL | 0 点、以降スキップ |
| **実行不能**（コマンドエラー、依存不足、DB 接続不可等） | **FAIL** | **0 点、以降スキップ** |

**重要**: 「実行できなかった」を PASS として扱わない。環境問題で満点を取らせない。

#### Layer 1 の 60 点付与条件

2a, 2b, 2c **全部パス** → 60 点、Layer 2 へ進む

### 3. Layer 2: Deterministic Quality (30 点)

`task-types.md` の task_type 別配点に従って測定する。

**plan.md の「Layer 2 検証コマンド」セクションに記載されたコマンドを全て実行する。**

全タスク共通:

#### 3a. テスト実行

plan.md の test コマンドを実行。記録: PASS 数 / 総数

#### 3b. 型チェック

plan.md の type check コマンドを実行。記録: エラー数、警告数

#### 3c. Lint / Format

plan.md の lint / format check コマンドを実行。記録: エラー数、警告数

#### 3d. ビルド

plan.md の build コマンドを実行。記録: exit code

#### 3e. UI タスク追加項目（task_type が ui-* の場合）

```bash
# Lighthouse
npx lhci autorun

# axe-core
npx @axe-core/cli <URL>

# Visual regression
npx playwright test --config=visual.config.ts

# <task_dir>/ui-checks.yaml の deterministic コマンド群を実行
```

#### 判定の原則

- **コマンド実行不能** → その項目は 0 点扱い
- 実行できないコマンドがあった場合、eval-report.md に具体的エラーを記録

### 4. Layer 3: LLM-as-judge (10 点)

該当するチェックリストを読む:

- UI タスク: `references/ui-heuristics.md` + `<task_dir>/ui-checks.yaml` の `heuristic_checklist`
- 非 UI タスク: `references/common-heuristics.md` の task_type セクション

**全タスク共通の追加チェック（scenario ↔ test の中身対応）:**

- [ ] 各テストの assertion が scenarios.md の対応シナリオの Then を実際に検証しているか
  - 例: S1 の Then が「/dashboard に遷移」なら、テストに `expect(page).toHaveURL('/dashboard')` 相当がある
  - テスト名だけ一致、中身が空や無関係な assertion しかない場合は fail

各項目を pass / fail で判定する:

- 差分と関連コードに基づいて判定
- 検証不能な項目（そのタスクで対象外）は `N/A` として総数から除外
- 自由記述スコア禁止

スコア計算:

```
layer3_score = 10 × (passed / (total - n_a))
```

### 5. 指摘の分類

各 fail 項目および追加の所見を以下に分類:

- **[修正可能]**: 次のイテレーションで直接修正できる
  - 例: テスト失敗、型エラー、assertion 追加
- **[修正不可能]**: 現在の制約では修正不能（理由を明記）
- **[設計起因]**: 計画・シナリオの見直しが必要
  - 特に「scenarios.md 自体の修正要求」はここに入れる
  - 例: 「S3 の Then が矛盾している」「受け入れシナリオに Q が不足」

### 6. レポート作成

`<task_dir>/iterations/iteration-NNN/eval-report.md` に以下の形式で書き出す:

```markdown
# 評価レポート (Iteration NNN)

## Task Type
{backend / ui-new / ui-change / refactor / bugfix}

## Layer 1: Hard Gate
- scenarios.md ハッシュ検証: PASS / FAIL
- scenario ↔ test 対応:
  - 期待シナリオ: S1, S2, S3, S4, S5
  - 実在テスト: S1, S2, S3, S5
  - 欠落: S4 ← FAIL 理由
- 受け入れテスト実行: PASS (X/Y) / FAIL / 実行不能
- 結果: **60 点 / 0 点**

{Layer 1 FAIL の場合、ここで終了}

## Layer 2: Deterministic Quality
| 項目 | 配点 | 測定値 | 獲得 |
|---|---|---|---|
| 全テストパス率 | 10 | X/Y | X |
| 型チェック | 10 | エラー N | X |
| ビルド | 5 | PASS/FAIL | X |
| カバレッジ | 5 | XX% | X |
| (UI) E2E | 5 | X/Y | X |
| ... | | | |
| **合計** | **30** | | **X** |

## Layer 3: LLM-as-judge
チェックリスト種別: {ui-heuristics / common-heuristics}
pass: X / fail: Y / N/A: Z
**layer3_score: XX / 10**

### 評価結果（シナリオ ↔ assertion 対応）
- S1: assertion OK（URL と welcome message を検証）
- S2: assertion **弱い**（エラー表示の検証が欠けている） ← fail
- ...

### その他 failed items
- [項目名]: 失敗理由

## 合計スコア: XX / 100

## 指摘一覧

### [修正可能]
- S2 のテストに「エラーメッセージが表示される」の assertion を追加
- ...

### [修正不可能]
- （該当なし / 理由を明記）

### [設計起因]
- S4 の Then が曖昧で検証不能 → scenarios.md の書き直しが必要

## 総評
（全体的な品質評価と改善の方向性）
```

## 制約

- **Edit を使わない**: 判定のみ。コードの修正は行わない
- **scenarios.md を変更しない**: ハッシュ検証の対象
- **acceptance-tests/ を変更しない**: 評価者は触らない（Generate の担当）
- **実装の経緯に言及しない**: 会話履歴がないため、推測で経緯を語らない
- **測定を飛ばさない**: 「たぶん通る」ではなく、必ず実行して結果を記録
- **自由記述スコアをしない**: Layer 3 は構造化チェックリストの pass/fail のみ

## 出力

- `<task_dir>/iterations/iteration-NNN/eval-report.md`

## 参考資料

- `references/eval-criteria.md`: 3 層スコアリングの基本ルール
- `references/task-types.md`: タスクタイプ別の Layer 2 配点
- `references/ui-heuristics.md`: UI タスクの Layer 3 チェックリスト
- `references/common-heuristics.md`: 非 UI タスクの Layer 3 チェックリスト
