---
name: dev-plan
description: |
  開発タスクの要件分析・受け入れテスト作成・実装計画策定を行うステージスキル。
  dev-loop オーケストレーターから Agent として呼び出される。
  受け入れテストを先に書き、ハッシュで固定する。
  トリガー: dev-plan, 実装計画, 要件分析
visibility: public
---

# Dev Plan - 実装計画ステージ

タスクの要件を分析し、受け入れテストを先に書き、実装計画を策定する。
受け入れテストは Plan 段階で固定され、以降のステージで改変できない。

## 入力

- オーケストレーターから渡される `task_dir`（例: `.dev-loop/20260419-103000-add-auth-feature/`）
- タスクの説明（Issue URL, ユーザー指示, エラー内容等）
- Escalation 時: 前回の計画と失敗理由（`<task_dir>/plan-history/` および `<task_dir>/latest-feedback.md`）

## パス規約

本ドキュメントで `<task_dir>` はオーケストレーターから渡されたタスクディレクトリ。
全ての書き込みはこのディレクトリ配下に限定する。

## 手順

### 1. 要件分析とタスクタイプ判定

タスクの入力を読み、以下を明確にする:

- 何を達成すべきか（受け入れ条件）
- タスクタイプ:
  - `backend`: バックエンド機能追加・修正
  - `ui-new`: 新規 UI 画面・コンポーネント
  - `ui-change`: 既存 UI の変更
  - `refactor`: リファクタリング
  - `bugfix`: バグ修正

曖昧な点がある場合は仮定を置き、plan.md に明記する。

### 2. コード調査

Grep, Glob, Read を使って:
- 変更が影響する範囲を特定する
- 既存のテストの有無を確認する
- 既存のコードコメント（Why コメント）を確認する
- デザイントークン・デザインシステムの存在を確認する（UI タスクの場合）

### 3. スキル選定

Generate に渡す参照スキルを選ぶ:

| 条件 | 渡すスキル |
|---|---|
| テストがある | `dot_claude/skills/testing/SKILL.md` |
| リファクタを含む | `dot_claude/skills/refactoring/SKILL.md` |
| TypeScript | `dot_claude/skills/typescript-strict/SKILL.md` |
| その他 | プロジェクトに応じて |

### 4. 受け入れテストの作成（必須）

**実装コードを書く前に、受け入れ条件を検証するテストを書く。**

`<task_dir>/acceptance-tests/` ディレクトリを作成し、テストファイルを配置する。

#### タスクタイプ別の受け入れテスト

**backend / bugfix:**
```
<task_dir>/acceptance-tests/
  acceptance.test.ts      # ユニット or 統合テスト
```

**ui-new / ui-change:**
```
<task_dir>/acceptance-tests/
  acceptance.test.ts      # コンポーネントテスト
  e2e.spec.ts             # Playwright E2E
```

**refactor:**
```
<task_dir>/acceptance-tests/
  behavior-preservation.test.ts  # 振る舞い不変を検証
```

#### 受け入れテストの原則

- 実装の詳細ではなく **振る舞い** を検証する
- テストは **この時点で FAIL することを確認** する（RED 状態を記録）
- テストコマンドを plan.md に明記する

### 5. ハッシュの記録

受け入れテストファイル群のハッシュを計算し、plan.md に記録する:

```bash
find <task_dir>/acceptance-tests -type f \( -name "*.test.*" -o -name "*_test.*" -o -name "*.spec.*" \) \
  | sort | xargs md5 | md5
```

このハッシュは Evaluate ステージで検証される。

### 6. UI タスクの追加作業

task_type が `ui-new` または `ui-change` の場合:

#### 6a. `<task_dir>/ui-checks.yaml` の生成

```yaml
ui_checks:
  deterministic:
    - name: "lighthouse"
      command: "npx lhci autorun --collect.url=http://localhost:3000/path"
    - name: "axe"
      command: "npx @axe-core/cli http://localhost:3000/path"
    - name: "design-tokens"
      command: "node scripts/check-design-tokens.js"

  heuristic_checklist:
    - "プライマリアクションに brand primary color が使われているか"
    - "フォームの section header が正しい階層（h2）で書かれているか"
```

#### 6b. ビジュアル baseline の準備

- 新規 UI (`ui-new`): baseline は実装後に生成される旨を明記
- 既存 UI 変更 (`ui-change`): 変更前の状態で baseline を取得するコマンドを plan.md に記載

### 7. 計画書作成

`<task_dir>/plan.md` に以下の形式で書き出す:

```markdown
# 実装計画

## メタ情報
- slug: {task-slug}
- task_type: backend | ui-new | ui-change | refactor | bugfix
- acceptance_hash: {受け入れテストのハッシュ値}

## 要件
（何を達成するか。受け入れ条件を箇条書きで）

## 受け入れ条件
- [ ] 条件 1（受け入れテスト: `acceptance-tests/path/to/test`）
- [ ] 条件 2
- ...

## 受け入れテスト
- パス: `<task_dir>/acceptance-tests/`
- 実行コマンド:
  ```
  npx playwright test <task_dir>/acceptance-tests/
  ```
- 現在の状態: RED（実装前なので全件 FAIL することを確認済み）

## 変更対象
- `path/to/file.ts`: 変更概要

## 実装方針
（アプローチの概要、TDD で進めるか、既存テストの有無）

## リスク・制約
（考慮すべき副作用、依存関係）

## 参照スキル
- `dot_claude/skills/refactoring/SKILL.md`
- `dot_claude/skills/testing/SKILL.md`
```

### 8. Escalation 時の追加対応

前回の feedback.md に [設計起因] の指摘がある場合（オーケストレーターが `<task_dir>/plan-history/plan-v{n}-{timestamp}.md` に旧 plan を退避済み）:

- 旧 plan.md (`<task_dir>/plan-history/` 配下の最新) を Read して分析
- アプローチを根本的に変更した計画を作成
- 必要に応じて受け入れテストも書き直す（受け入れ条件自体が不適切だった場合）
- 変更理由を新しい plan.md に明記

## 出力

- `<task_dir>/plan.md`
- `<task_dir>/acceptance-tests/`（受け入れテストファイル群）
- `<task_dir>/ui-checks.yaml`（UI タスクのみ）
