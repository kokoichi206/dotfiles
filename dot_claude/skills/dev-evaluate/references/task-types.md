# タスクタイプ別の評価軸

plan.md で指定されたタスクタイプに応じて、Layer 2 / Layer 3 の評価軸が切り替わる。

## 3 層スコアリングの基本構造

```
Layer 1: Hard Gate (0 or 60) — 完了条件の決定論的判定
Layer 2: Deterministic Quality (30) — 機械で測れる品質
Layer 3: LLM-as-judge (10) — 構造化ヒューリスティクスでの pass/fail
合計: 0〜100
合格: 95+
```

Layer 1 で FAIL したら **Layer 2/3 の評価はスキップし 0 点** で返す。

## タスクタイプ定義

### `backend` — バックエンド機能追加・修正

**Layer 1 ゲート:**
- 受け入れテスト全件パス

**Layer 2 (30 点):**
| 項目 | 配点 | 測定方法 |
|---|---|---|
| 全テストパス率 | 10 | テスト実行結果 |
| 型チェック・lint エラー 0 | 10 | tsc/mypy/eslint/ruff の実行結果 |
| ビルド成功 | 5 | ビルドコマンドの exit code |
| カバレッジ変化率 | 5 | 下がっていなければ満点 |

**Layer 3 (10 点):**
`references/common-heuristics.md` の backend チェックリストを使う

---

### `ui-new` — 新規 UI 画面・コンポーネント

**Layer 1 ゲート:**
- 受け入れテスト全件パス
- E2E テスト全件パス（H2: 受け入れ条件に UI が含まれる場合は必須）

**Layer 2 (30 点):**
| 項目 | 配点 | 測定方法 |
|---|---|---|
| E2E テストパス | 5 | Playwright / Cypress |
| Lighthouse スコア 90+ | 5 | lighthouse-ci |
| axe-core エラー 0 | 5 | `@axe-core/cli` |
| click target 44x44 基準 95%+ | 5 | スクリプトで DOM 検査 |
| デザイントークン準拠率 90%+ | 5 | tokens が定義されていれば（I1）|
| ビジュアル baseline 作成 | 5 | Playwright screenshot |

**Layer 3 (10 点):**
`references/ui-heuristics.md` + プロジェクトの `<task_dir>/ui-checks.yaml` の pass 率

---

### `ui-change` — 既存 UI の変更

**Layer 1 ゲート:**
- 受け入れテスト全件パス
- 意図しない箇所への影響がない（scope minimality）

**Layer 2 (30 点):**
| 項目 | 配点 | 測定方法 |
|---|---|---|
| E2E テストパス | 5 | |
| Visual regression が許容範囲内 | 5 | Playwright `toHaveScreenshot` |
| Lighthouse 低下なし | 5 | baseline からの差分 |
| axe-core エラー増加なし | 5 | baseline からの差分 |
| デザイントークン準拠率 | 5 | |
| スコープ最小性 | 5 | git diff のファイル数・行数 |

**Layer 3 (10 点):**
`references/ui-heuristics.md` + `<task_dir>/ui-checks.yaml`

---

### `refactor` — リファクタリング

**Layer 1 ゲート:**
- 既存テスト全件パス（振る舞い不変の証明）
- 新規テストは追加されていない（または既存テストの並び替え・可読性改善のみ）

**Layer 2 (30 点):**
| 項目 | 配点 | 測定方法 |
|---|---|---|
| 全テストパス率 | 10 | |
| 型チェック・lint エラー 0 | 10 | |
| 複雑度削減 | 5 | cyclomatic complexity (計測可能なら) |
| 重複削減 | 5 | similarity-ts 等 |

**Layer 3 (10 点):**
- DRY 違反の解消が妥当か
- 命名の改善
- 抽象化の妥当性

---

### `bugfix` — バグ修正

**Layer 1 ゲート:**
- バグを再現する回帰テストが追加されている
- 回帰テストが修正前は FAIL、修正後は PASS
- 既存テスト全件パス

**Layer 2 (30 点):**
| 項目 | 配点 | 測定方法 |
|---|---|---|
| 全テストパス率 | 10 | |
| 型チェック・lint エラー 0 | 10 | |
| 回帰テストの網羅性 | 5 | 正常系・境界値・異常系をカバー |
| 修正箇所の最小性 | 5 | git diff |

**Layer 3 (10 点):**
- 根本原因の特定の妥当性（コメントまたは PR description）
- 再発防止策の適切さ

## Layer 1 の判定ロジック

```
1. plan.md の「受け入れ条件」を一つずつ実行する
2. 全てパス → 60 点付与して Layer 2 へ
3. 一つでも FAIL → 0 点、以降スキップ
4. テストハッシュ不一致（受け入れテストが改変されている）→ 0 点、以降スキップ
```

## タスクタイプが不明な場合

plan.md に task_type が指定されていない場合、デフォルトで `backend` 扱いとする。
UI 変更を含むことが明らかな場合は ui-change / ui-new を推奨する旨をレポートに記載する。
