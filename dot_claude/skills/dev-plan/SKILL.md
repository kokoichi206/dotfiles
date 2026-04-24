---
name: dev-plan
description: |
  開発タスクの要件分析・受け入れシナリオ作成・実装計画策定を行うステージスキル。
  dev-loop オーケストレーターから Agent として呼び出される。
  scenarios.md を hash lock して spec として固定する（tests は lock しない）。
  トリガー: dev-plan, 実装計画, 要件分析
visibility: public
---

# Dev Plan - 実装計画ステージ

タスクの要件を分析し、**受け入れシナリオ（scenarios.md）を自然言語で書き**、実装計画を策定する。

**重要な設計原則:**
- spec = scenarios.md（自然言語、ハッシュロック）
- tests = acceptance-tests/（実装の一部、イテレーション中に変更可能）

テストコードを直接ハッシュロックしない。仕様と実装を分離する。

## 入力

- オーケストレーターから渡される `task_dir`（例: `.dev-loop/20260419-103000-add-auth-feature/`）
- タスクの説明（Issue URL, ユーザー指示, エラー内容等）
- Escalation 時: 前回の scenarios.md と失敗理由（`<task_dir>/plan-history/`, `<task_dir>/latest-feedback.md`）

## パス規約

本ドキュメントで `<task_dir>` はオーケストレーターから渡されたタスクディレクトリ。
全ての書き込みはこのディレクトリ配下に限定する。

## 手順

### 1. 要件分析とタスクタイプ判定

タスクの入力を読み、以下を明確にする:

- 何を達成すべきか
- タスクタイプ:
  - `backend`: バックエンド機能追加・修正
  - `ui-new`: 新規 UI 画面・コンポーネント
  - `ui-change`: 既存 UI の変更
  - `refactor`: リファクタリング
  - `bugfix`: バグ修正

曖昧な点がある場合は仮定を置き、scenarios.md の `## 要確認` セクションに明記する。

### 2. コード調査

Grep, Glob, Read を使って:
- 変更が影響する範囲を特定する
- 既存のテストの有無を確認する
- 既存のコードコメント（Why コメント）を確認する
- デザイントークン・デザインシステムの存在を確認する（UI タスクの場合）

#### CI 設定の確認（必須）

プロジェクトに CI 設定があれば、実行されている検査コマンドを読み取る:

- `.github/workflows/*.yml`
- `.gitlab-ci.yml`
- `.circleci/config.yml`
- `azure-pipelines.yml` など

抽出対象:
- test コマンド（例: `npm test`, `pytest`）
- lint コマンド（例: `npm run lint`, `ruff check`）
- type check（例: `tsc --noEmit`, `mypy`）
- build コマンド（例: `npm run build`）
- format check（例: `prettier --check`, `cargo fmt --check`）

これらを **plan.md の「Layer 2 検証コマンド」** に記録する。

### 3. スキル選定

Generate に渡す参照スキルを選ぶ:

| 条件 | 渡すスキル |
|---|---|
| テストがある | `dot_claude/skills/testing/SKILL.md` |
| リファクタを含む | `dot_claude/skills/refactoring/SKILL.md` |
| TypeScript | `dot_claude/skills/typescript-strict/SKILL.md` |
| その他 | プロジェクトに応じて |

### 4. 受け入れシナリオの作成（scenarios.md）

**実装コードを書く前に、受け入れシナリオを自然言語で書く。**

詳細な書き方は `references/scenario-patterns.md` を参照。

#### 原則（重要）

- **振る舞いベースのみ**: ユーザー視点・API 呼び出し側視点で記述
- **実装詳細を書かない**: セレクタ名、ライブラリ名、内部 API 名、URL パターン等は禁止
- **Given/When/Then 形式**: 前提・操作・期待値を構造化
- **One Sentence Without 'And'**: 各シナリオ名は「And を使わず一文」で書ける
- **S1, S2, ... の ID 必須**: Layer 1 で tests との対応検証に使われる

#### scenarios.md のフォーマット

```markdown
# 受け入れシナリオ

## メタ情報
- task_type: {backend / ui-new / ui-change / refactor / bugfix}

## S1: {振る舞いの要約（And なし一文）}
- **Given**: 前提条件
- **When**: 操作
- **Then**:
  - 観測可能な結果 1
  - 観測可能な結果 2

## S2: ...

## 要確認
- Q1: {LLM が気になった不明点}
- Q2: ...
```

#### 最低シナリオ数（タスクタイプ別）

| task_type | 最低数 |
|---|---|
| ui-new | 正常系 2+ 異常系 2+ エッジ 1 = **5+** |
| ui-change | 新シナリオ 1+ 既存回帰 1 = **2+** |
| backend | 正常系 2+ 異常系 1 = **3+** |
| bugfix | 回帰テスト 1+ 周辺回帰 1 = **2+** |
| refactor | 振る舞い不変 1+ = **1+** |

### 5. scenarios.md のハッシュ記録

scenarios.md のハッシュを共有スクリプトで計算し、ファイルに保存:

```bash
bash dot_claude/skills/dev-loop/scripts/compute_scenarios_hash.sh <task_dir>/scenarios.md > <task_dir>/scenarios-hash.txt
```

**この値は Evaluate で検証される。** scenarios.md が勝手に書き換えられていないことを保証する。
`shasum -a 256` / md5 の直打ちは禁止（共有スクリプトを使うこと）。

### 6. テストの初期テンプレート作成（任意、locked ではない）

`<task_dir>/acceptance-tests/` に各シナリオに対応するテストの **骨子** を書く。
テスト本体は dev-generate が完成させる。

**重要: acceptance-tests/ は lock しない。Generate が自由に改変できる。**

骨子の形式（例: Playwright）:

```typescript
// acceptance-tests/auth.spec.ts
import { test, expect } from '@playwright/test';

test('S1: 正しい認証情報でログイン成功', async ({ page }) => {
  // TODO: Given - DB に user@test.com/password のユーザーが存在する状態を用意
  // TODO: When - ログイン画面でメール・パスワードを入力してログインを実行
  // TODO: Then - ダッシュボード画面に遷移、ウェルカムメッセージにユーザー名、セッション確立
});

test('S2: 不正な認証情報でエラー表示', async ({ page }) => {
  // TODO: ...
});
```

**テスト名に S1, S2 の ID を含めること**（Layer 1 の対応チェックで使う）。

### 7. UI タスクの追加作業

task_type が `ui-new` または `ui-change` の場合:

#### 7a. `<task_dir>/ui-checks.yaml` の生成

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

#### 7b. アプリ起動方法の記載

plan.md の「アプリケーション起動」セクションに記載（Playwright webServer 設定など）。

### 8. plan.md の作成

`<task_dir>/plan.md` に以下の形式で書き出す:

```markdown
# 実装計画

## メタ情報
- slug: {task-slug}
- task_type: backend | ui-new | ui-change | refactor | bugfix
- scenarios_hash: {scenarios.md のハッシュ値}

## 概要
（何を達成するか、1 段落）

## 受け入れシナリオ
- パス: `<task_dir>/scenarios.md`（ハッシュ保護）
- シナリオ数: N（S1〜SN）

## 変更対象
- `path/to/file.ts`: 変更概要
- ...

## 実装方針
（アプローチの概要、使用技術、TDD で進めるか）

## Layer 2 検証コマンド（CI 設定から抽出）
- test: `npm test`
- lint: `npm run lint`
- type check: `tsc --noEmit`
- build: `npm run build`
- format check: `npx prettier --check .`

## アプリケーション起動（UI タスクのみ）
- dev server: `npm run dev`（Playwright webServer で自動化）
- DB: `docker compose up -d db`
- baseline snapshot: （ui-change のみ）実装前の画面キャプチャ取得

## リスク・制約
（考慮すべき副作用、依存関係）

## 参照スキル
- `dot_claude/skills/refactoring/SKILL.md`
- `dot_claude/skills/testing/SKILL.md`
```

### 9. Escalation 時の追加対応

前回の feedback.md に [設計起因] の指摘がある場合（オーケストレーターが旧 scenarios.md を `<task_dir>/plan-history/` に退避済み）:

- 旧 scenarios.md と 旧 plan.md を Read して分析
- アプローチを根本的に変更した計画を作成
- 変更理由を新しい plan.md に明記

#### scenarios.md の書き換え（早期 Plan Rewrite ルートのみ許可）

オーケストレーターから「scenarios 修正ルート」として起動された場合:

1. 旧 scenarios.md は既に `<task_dir>/plan-history/scenarios-v{n}-{timestamp}.md` に退避されている
2. 新しい scenarios.md を書く
3. 共有ハッシュスクリプトで新ハッシュを計算:
   ```bash
   bash dot_claude/skills/dev-loop/scripts/compute_scenarios_hash.sh <task_dir>/scenarios.md > <task_dir>/scenarios-hash.txt
   ```
4. 新 plan.md に以下を明記:
   - scenarios を書き換えた理由
   - 旧 scenarios との差分概要
   - 新しい scenarios_hash

**通常の Plan 起動時（このルート以外）では scenarios.md を改変しない。**

## 出力

- `<task_dir>/plan.md`
- `<task_dir>/scenarios.md`（ハッシュロック対象）
- `<task_dir>/scenarios-hash.txt`
- `<task_dir>/acceptance-tests/`（初期テンプレート、**ロックしない**）
- `<task_dir>/ui-checks.yaml`（UI タスクのみ）

## 参考資料

- `references/scenario-patterns.md`: scenarios.md の書き方、Given/When/Then パターン、禁止ワード
