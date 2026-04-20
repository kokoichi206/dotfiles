---
name: dev-generate
description: |
  実装計画に基づいて TDD でコードを実装するステージスキル。
  dev-loop オーケストレーターから Agent として呼び出される。
  受け入れテストは改変禁止（ハッシュで保護）。
  各イテレーションで新規 Agent が起動され、前回の試行錯誤を引き継がない。
visibility: public
---

# Dev Generate - 実装ステージ

計画に従って TDD でコードを実装する。受け入れテストを通すことが最優先。

## 入力

- オーケストレーターから渡される `task_dir` と `iteration`（例: `task_dir=.dev-loop/20260419-103000-add-auth-feature/`, `iteration=002`）
- `<task_dir>/plan.md`: 実装計画（必須）
- `<task_dir>/acceptance-tests/`: 受け入れテスト（**改変禁止**）
- `<task_dir>/acceptance-hash.txt`: 受け入れテストのハッシュ
- `<task_dir>/latest-feedback.md`: 統合済みフィードバック（2 周目以降のみ、シンボリックリンク）

## パス規約

本ドキュメントで `<task_dir>` はオーケストレーターから渡されたタスクディレクトリ。

## 絶対的な禁止事項

- **受け入れテスト（`<task_dir>/acceptance-tests/`）を編集・削除しない**
- **プロジェクトの既存テストを、通すために書き換えない**（TDD のアンチパターン）

これらはハッシュ検証で Evaluate ステージに検出される。
違反すると Layer 1 で 0 点になり、イテレーションが無駄になる。

## 手順

### 1. 計画の確認

`<task_dir>/plan.md` を読み、要件・受け入れ条件・task_type を把握する。

### 2. スキルの読み込み

plan.md の「参照スキル」セクションに列挙されたスキルファイルを Read で読む。
以降の実装では、それらの原則に従う。

### 3. フィードバック確認（2 周目以降）

`<task_dir>/latest-feedback.md` が存在する場合（シンボリックリンク）:
- **[修正可能]** の指摘に対応する
- **[修正不可能]** は無視してかまわない
- **[設計起因]** には触れない（オーケストレーターが Plan に差し戻す）

### 4. 初期状態の確認

受け入れテストが現在 FAIL することを確認する:

```bash
# 受け入れテストを実行
# 例: npx playwright test <task_dir>/acceptance-tests/
```

- **すべて FAIL**（1 周目、実装前の想定通り）→ Step 5 へ
- **一部 PASS**（何らかの理由で既に満たされている）→ そのまま Step 6 へスキップ可能

### 5. TDD 実装

要件ごとに RED → GREEN → REFACTOR サイクルを回す。

#### 判断: 追加のユニットテストを書くか

| 条件 | 判断 |
|---|---|
| テストフレームワークが存在する | TDD で追加ユニットテストを書く |
| テストがないが追加可能 | テストを追加して TDD で進める |
| テスト追加が現実的でない | 受け入れテストのみで進める |

#### RED: 失敗する追加テストを書く

1. 要件の一部を検証するテストを書く
2. テストを実行し、**失敗することを確認する**
3. テストファイルのハッシュを記録する

#### GREEN: テストを通す最小限のコードを書く

1. 最小限の実装を書く
2. テストを実行し、**全テストがパスすることを確認する**
3. テストファイルのハッシュを検証する
   - 一致: OK
   - 不一致: テストを書き換えて通した疑い。`git checkout` で戻して再実装

#### REFACTOR: 構造を改善する

1. テストが通った状態で実装コードを改善する
2. 参照スキルの原則に従う
3. テストを実行し、引き続きパスすることを確認する

### 6. 受け入れテスト通過の確認

各要件の実装後、**受け入れテストを実行して通ることを確認する**:

```bash
npx playwright test <task_dir>/acceptance-tests/
# またはプロジェクトの該当コマンド
```

- **すべて PASS** → Step 7 へ
- **一部 FAIL** → 失敗しているテストを確認し、追加実装を行う

### 7. UI タスクの追加確認（task_type が ui-* の場合）

```bash
# ビジュアル baseline（新規 UI の場合）
npx playwright test --update-snapshots

# <task_dir>/ui-checks.yaml の deterministic コマンドを実行
```

### 8. 最終確認

全要件の実装完了後:

```bash
# 全テスト実行（受け入れテスト + 既存テスト + 追加したテスト）
# 型チェック（tsc --noEmit, mypy 等）
# lint（eslint, ruff 等）
# ビルド（npm run build, cargo build 等）
```

すべてパスすることを確認する。

### 9. 受け入れテストのハッシュ検証（自己検証）

```bash
find <task_dir>/acceptance-tests -type f \( -name "*.test.*" -o -name "*_test.*" -o -name "*.spec.*" \) \
  | sort | xargs md5 | md5
```

`<task_dir>/acceptance-hash.txt` の値と一致することを確認する。
一致しない場合、どこかで受け入れテストが改変されている。`git checkout` で戻す。

### 10. イテレーションログ

`<task_dir>/iteration-log.md` に追記する:

```markdown
## Iteration NNN

### TDD サイクル
| 要件 | RED | GREEN | REFACTOR | ハッシュ検証 |
|---|---|---|---|---|
| 要件 A | FAIL 確認 | PASS | 完了 | OK |
| 要件 B | FAIL 確認 | PASS | 完了 | OK |

### 変更内容
- 変更の要約

### 対応した指摘（2 周目以降）
- [修正可能] XX: 対応内容

### 受け入れテスト
- PASS (X/Y)

### 最終確認
- 全テスト: PASS (XX/XX)
- 型チェック: PASS / N/A
- lint: PASS / N/A
- ビルド: PASS / N/A

### 受け入れテストハッシュ
- plan.md の hash: XXX
- 現在の hash: XXX
- 一致: OK
```

## その他の禁止事項

- **GREEN フェーズでテストファイルを編集しない**: テストを通すのは実装コードの責務
- **計画に書かれていない変更をしない**: スコープ外の修正はしない
- **暗黙的 fallback を書かない**: `?? 'unknown'`, `catch { return '' }` 等
- **「念のため」コードを書かない**: YAGNI を徹底する

## 出力

- 実装されたコード変更
- 追加のユニットテスト（TDD 適用時）
- `<task_dir>/iteration-log.md` への追記
- ビジュアル baseline スナップショット（UI 新規の場合）
