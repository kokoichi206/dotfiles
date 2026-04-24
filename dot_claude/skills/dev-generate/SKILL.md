---
name: dev-generate
description: |
  受け入れシナリオに基づいて実装・テスト作成を行うステージスキル。
  dev-loop オーケストレーターから Agent として呼び出される。
  scenarios.md は改変禁止（ハッシュで保護）、tests は柔軟に変更可能。
  各イテレーションで新規 Agent が起動され、前回の試行錯誤を引き継がない。
visibility: public
---

# Dev Generate - 実装ステージ

`<task_dir>/scenarios.md` に記述された受け入れシナリオを満たす実装とテストを書く。

**重要な設計原則:**
- scenarios.md = spec（ハッシュロック、改変禁止）
- acceptance-tests/ = 実装の一部（柔軟に作成・変更可能）
- 実装コード = 自由

テストは scenarios.md を **検証するためのツール** であって仕様ではない。
lint / import / format / セレクタ選び等は自由に調整してよい。

## 入力

- オーケストレーターから渡される `task_dir` と `iteration`
- `<task_dir>/plan.md`: 実装計画（必須）
- `<task_dir>/scenarios.md`: 受け入れシナリオ（**改変禁止**）
- `<task_dir>/scenarios-hash.txt`: scenarios.md のハッシュ
- `<task_dir>/acceptance-tests/`: テスト（**柔軟に変更可**、初期テンプレはある場合とない場合がある）
- `<task_dir>/latest-feedback.md`: 統合済みフィードバック（2 周目以降のみ）

## 絶対的な禁止事項

- **`<task_dir>/scenarios.md` を編集・削除しない**
  - ハッシュ検証で Evaluate に検出される
  - 違反すると Layer 1 で 0 点になる
  - 仕様の変更が必要なら [設計起因] 指摘として feedback で伝える（Plan Rewrite で対処される）
- **プロジェクトの既存テストを、通すために書き換えない**（TDD のアンチパターン）
- **暗黙的 fallback を書かない**（`?? 'unknown'`, `catch { return '' }` 等）
- **「念のため」コードを書かない**（YAGNI）
- **計画・シナリオに書かれていない機能を追加しない**（スコープクリープ禁止）

## できること（柔軟性）

- `<task_dir>/acceptance-tests/` の追加・修正・リファクタリング
- テストファイルの lint / format / import 修正
- セレクタ戦略の変更（`getByRole` / `getByText` / `getByTestId` 等）
- テストフレームワーク固有の設定調整
- baseline snapshot の更新

## 手順

### 1. 入力の確認

`<task_dir>/plan.md` と `<task_dir>/scenarios.md` を読み、以下を把握:
- 要件と受け入れシナリオ（S1, S2, ...）
- task_type と Layer 2 検証コマンド
- 変更対象ファイル

### 2. スキルの読み込み

plan.md の「参照スキル」セクションに列挙されたスキルファイルを Read で読む。
以降の実装では、それらの原則に従う。

### 3. フィードバック確認（2 周目以降）

`<task_dir>/latest-feedback.md` が存在する場合:
- **[修正可能]** の指摘に対応する
- **[修正不可能]** は無視してかまわない
- **[設計起因]** には触れない（オーケストレーターが Plan に差し戻す）

### 4. テストの整備（acceptance-tests/）

scenarios.md の各シナリオ（S1, S2, ...）に対応するテストを `<task_dir>/acceptance-tests/` に整備する。

#### 原則

- **各シナリオに 1 つ以上のテストを対応させる**
- **テスト名にシナリオ ID を含める**: 例 `test('S1: 正しい認証情報でログイン成功', ...)`
- **Given/When/Then を意識する**: Arrange-Act-Assert に落とす
- **セレクタは振る舞いベース優先**: `getByRole` → `getByLabel` → `getByText` → `getByTestId` の順

#### 例（Playwright）

scenarios.md:
```markdown
## S1: 正しい認証情報でログイン成功
- Given: DB に user@test.com/password のユーザーが存在する
- When: ログイン画面でメール・パスワードを入力してログインを実行
- Then: ダッシュボードに遷移、ウェルカムメッセージが表示
```

acceptance-tests/auth.spec.ts:
```typescript
test('S1: 正しい認証情報でログイン成功', async ({ page }) => {
  // Given: DB 準備（fixture で）
  // When
  await page.goto('/login');
  await page.getByLabel('メール').fill('user@test.com');
  await page.getByLabel('パスワード').fill('password');
  await page.getByRole('button', { name: 'ログイン' }).click();

  // Then
  await expect(page).toHaveURL('/dashboard');
  await expect(page.getByText(/ようこそ/)).toBeVisible();
});
```

#### 初期状態の確認

テストが scenarios を正しく検証していることを確認するため、実装前に `<task_dir>/acceptance-tests/` を実行して **FAIL することを確認**（RED）:

```bash
# 例: npx playwright test <task_dir>/acceptance-tests/
```

全テストが最初から PASS するなら、テストが何も検証していない（assertion が弱い）可能性が高い。見直す。

### 5. TDD 実装

scenarios の各シナリオに対応する機能を、RED → GREEN → REFACTOR で実装する。

#### RED

対応するテストを追加または強化（Step 4 で骨子がある場合は中身を埋める）。
テスト実行で FAIL することを確認。

#### GREEN

テストを通す最小限の実装を書く。

- 計画に書かれた変更だけを行う
- スコープ外の修正はしない
- 暗黙的 fallback を書かない

#### REFACTOR

テストが通った状態で実装コード（およびテストコード自体）を改善。
- 参照スキル（refactoring/SKILL.md 等）の原則に従う
- 命名改善、重複除去、ネスト削減、テストの読みやすさ向上

### 6. scenarios.md のハッシュ検証（自己検証）

**共有スクリプトを使う**:

```bash
bash dot_claude/skills/dev-loop/scripts/compute_scenarios_hash.sh <task_dir>/scenarios.md
```

`<task_dir>/scenarios-hash.txt` の値と一致することを確認する。
一致しない場合、どこかで scenarios.md が改変されている。`git checkout` で戻す。

### 7. 受け入れテスト通過の確認

すべてのシナリオが PASS することを確認:

```bash
npx playwright test <task_dir>/acceptance-tests/
# またはプロジェクトの該当コマンド
```

- すべて PASS → Step 8 へ
- 一部 FAIL → 実装を追加・修正

### 8. UI タスクの追加確認（task_type が ui-* の場合）

```bash
# ビジュアル baseline（新規 UI の場合）
npx playwright test --update-snapshots

# <task_dir>/ui-checks.yaml の deterministic コマンドを実行
```

### 9. 最終確認（plan.md の Layer 2 検証コマンド全部）

```bash
# plan.md の「Layer 2 検証コマンド」セクションに記載されたもの全部
npm test
tsc --noEmit
npm run lint
npm run build
npx prettier --check .
```

すべてパスすることを確認する。

### 10. イテレーションログ

`<task_dir>/iteration-log.md` に追記する:

```markdown
## Iteration NNN

### 対応シナリオ
- S1: 実装完了、テストパス
- S2: 実装完了、テストパス
- S3: テスト強化のみ（既存実装で対応済み）

### TDD サイクル
| シナリオ | RED | GREEN | REFACTOR |
|---|---|---|---|
| S1 | FAIL 確認 | PASS | 完了 |
| S2 | FAIL 確認 | PASS | — |

### 変更内容
- 変更の要約

### 対応した指摘（2 周目以降）
- [修正可能] XX: 対応内容

### 受け入れテスト
- 全件 PASS (X/X)

### 最終確認
- 全テスト: PASS (XX/XX)
- 型チェック: PASS / N/A
- lint: PASS / N/A
- ビルド: PASS / N/A
- format check: PASS / N/A

### scenarios.md ハッシュ
- plan.md の hash: XXX
- 現在の hash: XXX
- 一致: OK
```

## 出力

- 実装されたコード変更
- `<task_dir>/acceptance-tests/` の整備・追加（柔軟に変更）
- 追加のユニットテスト（TDD 適用時）
- `<task_dir>/iteration-log.md` への追記
- ビジュアル baseline スナップショット（UI 新規の場合）
