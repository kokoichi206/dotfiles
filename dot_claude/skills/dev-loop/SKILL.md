---
name: dev-loop
description: |
  dev-plan → dev-generate → dev-evaluate → dev-external-review → Verify のループを管理するオーケストレーター。
  3 層スコアリング (Hard Gate + Deterministic + LLM-as-judge) で 95 点以上を目指す Ralph 式ループ。
  トリガー: dev-loop, 開発ループ, オーケストレーターで実装, ループで開発, 多段レビュー実装, ralph loop
---

# Dev Loop - オーケストレーター

各ステージスキルを Agent として呼び出し、ファイルベースで成果物を受け渡す薄い司令塔。
自分が実装やレビューを行うことはない。判定と対話だけを担う。

## 設計方針

- **95 点閾値**: 合格ラインを高く設定して評価の解像度を強制する
- **段階的イテレーション戦略**: 同じ修正を繰り返しても収束しないなら、やり方を変える
- **受け入れテスト先行**: Plan で受け入れテストを固定（ハッシュ検証）
- **決定論的判定を最大化**: Layer 1/2 で 90 点が決まる。LLM の主観は Layer 3 の 10 点のみ
- **タスク単位でディレクトリ分離**: slug ベースで `.dev-loop/<slug>/` を使う（並行実行・過去保存対応）

## ステージエージェント一覧

各ステージは `dot_claude/agents/` に定義された専用 subagent として呼び出す。
ツール権限がシステムレベルで制限されている（例: dev-evaluate は Edit 不可）。

| ステージ | subagent_type | 付与ツール | 禁止ツール |
|---|---|---|---|
| Plan | `dev-plan` | Read, Grep, Glob, Write, Bash, WebFetch | **Edit**（既存コード保護） |
| Generate | `dev-generate` | Read, Edit, Write, Bash, Grep, Glob | — |
| Evaluate | `dev-evaluate` | Read, Grep, Glob, Bash, Write | **Edit**（評価中の改変防止） |
| External Review | `dev-external-review` | Bash, Read, Write | **Edit, Grep, Glob** |

## 設計の核: spec と tests の分離

- **spec = `scenarios.md`（自然言語、ハッシュロック）**: 人間承認、不変
- **tests = `acceptance-tests/`（実装の一部、柔軟）**: Generate が整備・調整

この分離により、lint/import/format/セレクタ等の実装詳細は柔軟に調整できる一方、
「何を満たすべきか」の spec はブレない。

## ファイルベース通信（タスクディレクトリ構造）

タスクディレクトリ名は `YYYYMMDD-HHMMSS-<base-slug>` 形式のタイムスタンプ prefix 付き。
`ls .dev-loop/` で辞書式ソート = 時系列ソートになる。

```
.dev-loop/
  20260419-103000-add-auth-feature/  ← <task-slug> = timestamp-prefix + base-slug
    plan.md                       ← dev-plan の出力（実装計画）
    scenarios.md                  ← dev-plan の出力（受け入れシナリオ、★ ハッシュロック）
    scenarios-hash.txt            ← scenarios.md のハッシュ
    acceptance-tests/             ← テスト（★ ロックしない、Generate が整備）
    ui-checks.yaml                ← UI タスクのプロジェクト固有チェック
    iterations/
      iteration-001/
        eval-report.md            ← dev-evaluate の出力
        external-review.md        ← dev-external-review の出力
        feedback.md               ← Verify の統合結果
      iteration-002/
        ...
    latest-feedback.md            ← iterations/iteration-NNN/feedback.md へのシンボリックリンク
                                    dev-generate はこれを読む
    plan-history/                 ← Escalation で書き直された旧 plan / scenarios
      plan-v1-{timestamp}.md
      scenarios-v1-{timestamp}.md
    iteration-log.md              ← 全イテレーションの記録
    score-log.md                  ← スコアの根拠と推移

  latest -> 20260419-103000-add-auth-feature  ← 最新の task_dir への symlink
```

## 並行実行

同一リポジトリ内で異なるタスクを並行実行できる。timestamp prefix が秒単位で一意なので衝突しない:

```
.dev-loop/
  20260419-103000-add-auth-feature/  ← task A（10:30:00 開始）
  20260419-114530-fix-payment-bug/   ← task B（11:45:30 開始）
```

同じタスクを後で再開・派生させたい場合も別ディレクトリになり、過去の記録が保持される。

## 実行手順

### Stage 0: タスク受付と task_dir 決定

1. ユーザーからタスクを受け取る
2. タスクの説明から base-slug を生成する
   - 英小文字 + ハイフン、最大 50 文字
   - 例: "Add authentication feature" → `add-auth-feature`
   - 例: "Fix payment bug in checkout" → `fix-payment-bug-checkout`
   - Issue 番号があれば優先: `issue-123-add-auth`
3. 現在時刻から timestamp prefix を生成する
   ```bash
   date +%Y%m%d-%H%M%S
   # 例: 20260419-103000
   ```
4. task_slug = `<timestamp>-<base-slug>` を組み立てる
   - 例: `20260419-103000-add-auth-feature`
5. ユーザーに確認する:
   - 候補を提示して「これで進めていい？」と聞く
   - ユーザーが base-slug の変更を求めたら反映する（timestamp は変えない）
6. `.dev-loop/<task_slug>/` を作成する（timestamp 付きなので通常は衝突しない）
7. `.dev-loop/latest` symlink を今回の task_dir に張り替える:
   ```bash
   ln -sfn "<task_slug>" .dev-loop/latest
   ```
8. `.gitignore` に `.dev-loop/` が含まれていなければ追加する

以降、すべての Agent 呼び出しで `task_dir = .dev-loop/<task_slug>/` を引き渡す。

**latest symlink の使い道:**
- `.dev-loop/latest/plan.md` で現在作業中のタスクの計画を即参照可能
- Stage 6 Report 後も張り替えずに残すので、「最後に取り組んだタスク」を追跡できる

### Stage 1: Plan

```
Agent({
  subagent_type: "dev-plan",
  description: "dev-plan: 実装計画・受け入れシナリオ策定",
  prompt: `
    task_dir = .dev-loop/<slug>/

    ## タスク
    {ユーザーから受け取ったタスクの説明}

    task_dir 配下に以下を作成してください:
    - scenarios.md（受け入れシナリオ、ハッシュロック対象）
    - scenarios-hash.txt
    - plan.md（実装計画）
    - acceptance-tests/（テストの初期テンプレート、ロックしない）
    - ui-checks.yaml（UI タスクの場合）
  `
})
```

Agent 完了後:
1. `<task_dir>/scenarios.md` と `<task_dir>/plan.md` を Read する
2. **ユーザーに受け入れシナリオ（scenarios.md）と計画（plan.md）を提示し、承認を得る**
   - 特に scenarios.md の過不足を人間に確認してもらう（スペック自体の品質を担保する唯一のゲート）
   - scenarios.md に `## 要確認` があればそれに回答を得る
3. 修正要求があれば Agent を再起動

### Stage 2: Generate

イテレーション番号 N を 001, 002, ... と振る。

```
Agent({
  subagent_type: "dev-generate",
  description: "dev-generate: 実装 (Iteration N)",
  prompt: `
    task_dir = .dev-loop/<slug>/
    iteration = NNN

    Iteration NNN の実装を開始してください。
    <task_dir>/plan.md と、2 周目以降は <task_dir>/latest-feedback.md を参照してください。
    iteration-log.md は <task_dir>/iteration-log.md に追記してください。
  `
})
```

**各イテレーションで新しい Agent を起動する。** 前回の試行錯誤は引き継がない。

### Stage 3 & 4: Evaluate + External Review（並列）

Stage 3 & 4 の前に、オーケストレーターが `<task_dir>/iterations/iteration-NNN/` を作成する。

この 2 つは独立しているため、**並列で実行する**（単一のメッセージで 2 つの Agent tool を呼ぶ）。

```
Agent({
  subagent_type: "dev-evaluate",
  description: "dev-evaluate: 3 層スコアリング (Iteration NNN)",
  prompt: `
    task_dir = .dev-loop/<slug>/
    iteration = NNN

    Iteration NNN の実装を評価してください。
    結果は <task_dir>/iterations/iteration-NNN/eval-report.md に書いてください。
  `
})

Agent({
  subagent_type: "dev-external-review",
  description: "dev-external-review: 外部モデルレビュー (Iteration NNN)",
  prompt: `
    task_dir = .dev-loop/<slug>/
    iteration = NNN

    Iteration NNN の実装に対して外部レビューを実行してください。
    結果は <task_dir>/iterations/iteration-NNN/external-review.md に書いてください。
  `
})
```

### Stage 5: Verify（オーケストレーター自身）

**このステージだけはオーケストレーターが直接行う。**

1. `<task_dir>/iterations/iteration-NNN/eval-report.md` と同 `external-review.md` を Read する
2. 両者のスコアと指摘を統合する

**統合スコアの計算式:**

```
統合スコア = min(evaluate_score, external_score)
```

`min()` を使う理由: 片方が甘くても通らないようにするため（評価ゲーミング対策）。
平均や重み付けにすると「Evaluate 甘く、External でカバー」のような抜け道が生まれる。

**乖離チェック:**

```
|evaluate_score - external_score| >= 20
```

20 点以上の乖離は、どちらかが誤判定している可能性が高い。
この場合は Human Escalation を検討する（短絡条件で後述）。

3. `<task_dir>/score-log.md` にスコア推移を追記する:

```markdown
## Iteration NNN
- Evaluate: XX/100 (L1: X, L2: Y, L3: Z)
- External: XX/100
- 統合スコア: XX（= min(Evaluate, External)）
- 乖離: Δ（evaluate - external）
- 指摘件数: [修正可能] X, [修正不可能] Y, [設計起因] Z
```

4. 指摘を重複除去し、`<task_dir>/iterations/iteration-NNN/feedback.md` に書き出す:

```markdown
# フィードバック（Iteration NNN）

## 統合スコア: XX/100

## 前回からの推移
- Iteration N-1: XX → Iteration N: XX（差分 ±X）

## [修正可能]
- 指摘内容と対応方針

## [修正不可能]
- 指摘内容と理由

## [設計起因]
- 指摘内容と影響範囲
```

5. シンボリックリンク `<task_dir>/latest-feedback.md` を今回の `iterations/iteration-NNN/feedback.md` に張り替える:

```bash
ln -sf "iterations/iteration-NNN/feedback.md" "<task_dir>/latest-feedback.md"
```

6. 判定ロジック（段階的イテレーション戦略）を適用する

### 判定ロジック

```
イテレーション数 N に応じて戦略を変える:

N = 1-3: Incremental Fix（通常の修正ループ）
  - 統合スコア >= 95 → Complete
  - それ以外 → Generate へ戻る

N = 4: Batch Fix
  - 統合スコア >= 95 → Complete
  - それ以外 → Generate へ戻る
    特殊指示: 「全 [修正可能] 指摘を一括で対応」と feedback.md に追記

N = 5: Plan Rewrite（Escalation）
  - 統合スコア >= 95 → Complete
  - それ以外 → 既存 plan.md を <task_dir>/plan-history/plan-v{n}-{timestamp}.md に退避し、
    Stage 1 を再実行

N = 6-7: Incremental Fix（Plan 書き直し後）
  - 統合スコア >= 95 → Complete
  - N = 7 で 95 未満 → Human Escalation
```

判定テーブル:

| N | 条件 | アクション |
|---|---|---|
| 1-3 | スコア 95+ | Complete → Stage 6 |
| 1-3 | スコア < 95 | Loop → Stage 2 (Incremental Fix) |
| 4 | スコア 95+ | Complete → Stage 6 |
| 4 | スコア < 95 | Loop → Stage 2 (Batch Fix 指示付き) |
| 5 | スコア 95+ | Complete → Stage 6 |
| 5 | スコア < 95 | Escalate → Stage 1 (Plan Rewrite) |
| 6 | スコア 95+ | Complete → Stage 6 |
| 6 | スコア < 95 | Loop → Stage 2 |
| 7 | スコア 95+ | Complete → Stage 6 |
| 7 | スコア < 95 | **Human Escalation** → Stage 6 (最善状態で報告) |

### 短絡条件

以下の場合は通常のループを中断する:

**Human Escalation（人間判断へ）:**

- Layer 1 で 3 回連続 0 点（完了条件を満たせない）
  → 要件が曖昧 or 達成不可能の可能性
- 統合スコアが 3 回連続で改善していない（差分 ±2 以内）
  → 現在のアプローチで上限に達している
- Evaluate と External のスコア乖離が 2 回連続で 20 点以上
  → 評価者のどちらかがバイアスを持っている可能性

**早期 Plan Rewrite（scenarios 修正ルート）:**

- [設計起因] の指摘が「**scenarios.md 自体の修正を要求**」するケースが 2 回連続で出た場合
  → iteration 5 を待たず、即 Plan Rewrite に飛ぶ
  → 通常の Plan Rewrite 回数制限（最大 1 回）にはカウントしない
  → ただし Plan Rewrite 時のみ `<task_dir>/scenarios.md` の再作成を許可する
    - 旧 scenarios.md は `<task_dir>/plan-history/scenarios-v{n}-{timestamp}.md` に退避
    - 新しい scenarios_hash を新 plan.md に記録
    - 旧 scenarios-hash.txt も history に退避し、新しい値を `<task_dir>/scenarios-hash.txt` に書く
  → 修正された scenarios.md は人間に再度提示して承認を得る

**このルートの制約:**

- scenarios.md の書き換えは Plan Rewrite 経由でのみ可能（直接の iteration 内では禁止）
- dev-generate / dev-evaluate は scenarios.md を改変できない（acceptance-tests/ は自由）
- ハッシュ保護は Plan Rewrite 後も維持される（新しいハッシュで固定）
- 旧 scenarios は plan-history/ に残るため監査可能

### Stage 6: Report（オーケストレーター自身）

最終報告:
- タスクの slug と task_dir のパス
- 要件とタスクタイプ
- 最終スコア（Layer 別の内訳）
- 残存指摘とその分類
- イテレーション回数と戦略の推移
- `<task_dir>/score-log.md` の要約
- Human Escalation の場合: 現状のベスト状態と人間に判断を求めたい点

## オーケストレーターの原則

- **自分でコードを書かない**: 実装は dev-generate に委譲する
- **自分でレビューしない**: 評価は dev-evaluate と dev-external-review に委譲する
- **判定と対話だけを担う**: Verify の判定ロジックとユーザーコミュニケーションが責務
- **slug と iteration 番号を管理する**: 各 Agent 呼び出しに task_dir と iteration を渡す
- **iteration ディレクトリを事前作成**: Stage 3/4 の前に `iterations/iteration-NNN/` を作る
- **latest-feedback.md を張り替える**: 各 Verify 後に symlink を更新

## 評価ゲーミング対策（運用上の注意）

1. **受け入れテストのハッシュ検証**: Plan で固定、Evaluate で検証
2. **決定論的判定を最大化**: Layer 1 (60) + Layer 2 (30) で 90 点。LLM 判定は 10 点のみ
3. **External Review の独立性**: Evaluate と External Review のスコアが 20 点以上乖離したら Human Escalation を検討
4. **全イテレーションの保存**: `iterations/iteration-NNN/` に各回の eval-report / external-review / feedback を残す
5. **score-log.md**: スコア推移と指摘の対応履歴を残し、後から人間が検証可能にする
