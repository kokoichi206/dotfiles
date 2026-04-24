# 評価基準（3 層スコアリング）

Ralph Loop の backpressure 思想に基づく 3 層モデル。
**LLM 判定の比重を下げ、決定論的判定を最大化する** ことで評価ゲーミングを防ぐ。

## 設計原則: spec と tests の分離

- **spec = `<task_dir>/scenarios.md`（自然言語、ハッシュロック）**
- **tests = `<task_dir>/acceptance-tests/`（実装の一部、柔軟に変更可）**

テストコード自体はハッシュロックしない。テストは **scenarios を検証するツール** であって spec ではない。
これにより、lint/import/format/セレクタ選び等の実装詳細は柔軟に調整できる。
一方、spec（scenarios.md）は固定されるので「何を満たすべきか」はブレない。

## 3 層構造

```
┌─────────────────────────────────────────────┐
│ Layer 1: Hard Gate (0 or 60)                 │
│   3 段階判定:                                 │
│   1. scenarios.md ハッシュ検証                │
│   2. scenario ↔ test ID 対応                  │
│   3. 受け入れテスト全件パス（実行不能も FAIL）│
│   いずれか 1 つ FAIL → 0 点（Layer 2/3 スキップ）│
│   全部 PASS → 60 点、Layer 2 へ進む          │
└─────────────────────────────────────────────┘
                ↓ PASS
┌─────────────────────────────────────────────┐
│ Layer 2: Deterministic Quality (30 点)       │
│   機械で測れるもの（テスト、型、lint、ビルド等）│
│   plan.md の「Layer 2 検証コマンド」を実行    │
│   タスクタイプ別の配点は task-types.md 参照   │
└─────────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────────┐
│ Layer 3: LLM-as-judge (10 点)                │
│   構造化チェックリストに対する pass/fail      │
│   + scenario ↔ assertion 対応検証             │
│   自由記述でスコアさせない                    │
└─────────────────────────────────────────────┘

合計: 0〜100 点
合格: 95+ 点
```

## Layer 1: Hard Gate の原則

### 判定ロジック（3 段階）

```
Step 1. scenarios.md のハッシュ検証
   （共有スクリプト dot_claude/skills/dev-loop/scripts/compute_scenarios_hash.sh を使用）
   - plan.md / scenarios-hash.txt の値と一致しない → 0 点

Step 2. scenario ↔ test ID 対応チェック
   - scenarios.md から S1, S2, ... を抽出
   - acceptance-tests/ のテスト名から S1, S2, ... を抽出
   - 欠落や余剰があれば → 0 点

Step 3. 受け入れテスト実行
   - 全件 PASS → Layer 1 通過、60 点付与
   - 一件でも FAIL → 0 点
   - 実行不能（コマンドエラー、依存不足、環境問題等）→ 0 点
```

### 重要: 「実行できなかった」と「PASS した」の区別

環境問題（DB 未起動、依存パッケージ不足、コマンド not found 等）でテストが実行できなかった場合、
**PASS として扱わない。0 点（FAIL）として扱う。**

理由: 実行不能を満点で通すと、評価ゲーミングの穴になる:
- 依存パッケージを壊して「テストが動かない」状態にできる
- DB connection を破壊してテストをスキップできる
- CI が落ちるが Evaluate だけ通る状態が作れる

### なぜ scenarios.md のハッシュ検証が必要か

scenarios.md は **人間が承認した spec** である。
Generate / Evaluate エージェントがこれを改変して「合格」にすることを防ぐため、ハッシュで改変を検出する。

一方、acceptance-tests/ は実装の一部なのでハッシュロックしない（自由に変更可能）。

### なぜ scenario ↔ test ID 対応チェックが必要か

scenarios を spec として固定しても、LLM が対応するテストを省略するリスクがある:
- 「通しやすい 3 件だけをテスト化、残り 2 件は省略」
- 人間は scenarios.md だけ承認してテストコードまで読まないことが多い

ID 対応の機械チェックで、この省略を検出する。

### なぜ共有スクリプトを使うか

`md5` / `md5sum` / 自前パイプは OS や locale で挙動が変わる。
Plan が計算したハッシュと Evaluate が計算したハッシュが一致しないと、
正しい実装でも常に Layer 1 FAIL になる。

共有スクリプト `dot_claude/skills/dev-loop/scripts/compute_scenarios_hash.sh` を
すべてのステージで使うことで、この不整合を防ぐ。

## Layer 2: Deterministic Quality の原則

- **必ずコマンドを実行して結果を記録する**（「テストはたぶん通る」と書かない）
- 測定値を具体的に記録する（「70%」ではなく「カバレッジ 68.3%」）
- plan.md の「Layer 2 検証コマンド」に記載されたコマンドを全て実行
- タスクタイプ別の配点は `task-types.md` を参照
- **コマンド実行不能** は該当項目 0 点扱い

## Layer 3: LLM-as-judge の原則

- **チェックリスト項目ごとに pass / fail を返す**
- 自由記述で「全体的に良い」のような評価をしない
- 各項目は **検証可能な粒度** に分解する

### 全タスク共通の追加チェック（scenario ↔ assertion 対応）

Layer 3 には必ず以下を含める:

- [ ] 各テストの assertion が scenarios.md の対応シナリオの Then を実際に検証している
  - 例: S1 の Then が「/dashboard に遷移」なら、テストに URL 検証の assertion がある
  - テスト名だけ一致、中身が空や無関係な assertion しかない場合は fail
  - 「ID は対応しているがテストが弱い」を防ぐ

良い項目の例:
- 「border-radius の種類が 3 つ以内に収まっているか」
- 「全ての `<img>` に `alt` 属性が設定されているか」
- 「S1 のテストに URL 遷移の assertion が含まれているか」

悪い項目の例（自由度が高すぎ）:
- 「UI が使いやすいか」
- 「コードが綺麗か」

### スコア計算

```
score = 10 × (passed_items / total_items)
```

例: 20 項目中 18 pass → 10 × 0.9 = 9 点

### チェックリストの出所

- 共通: `ui-heuristics.md` / `common-heuristics.md`
- プロジェクト固有: `<task_dir>/ui-checks.yaml` の `heuristic_checklist`

両者をマージして評価する。

## スコア判定

| スコア | 判定 |
|---|---|
| 95-100 | **合格** → Complete |
| 60-94 | [修正可能] な指摘を対応して Loop |
| 1-59 | [設計起因] の疑い。Escalation 検討 |
| 0 | Layer 1 FAIL（ハッシュ改変 / テスト対応欠落 / テスト実行失敗） |

## 評価ゲーミング対策の層構造

1. **scenarios.md のハッシュ検証**: spec 自体の改変を検出
2. **scenario ↔ test ID 対応**: テスト化漏れを検出
3. **scenario ↔ assertion 対応（Layer 3）**: テスト中身の空洞化を検出
4. **Layer 1/2 で 90 点が決まる**: LLM の主観が大きな影響を持たない
5. **実行不能を FAIL 扱い**: テストを壊して満点を防ぐ
6. **score-log.md**: スコア推移と指摘の対応履歴を残し、後から人間が検証可能
