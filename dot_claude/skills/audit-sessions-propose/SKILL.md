---
name: audit-sessions-propose
description: 過去の Claude Code セッションログ（対象オーナー限定）から人間発話を抽出し、改善を決定論的な仕組み（skill/設定・ルール/lint/プロンプト）へ移せる箇所を並列分析して、承認用チェックリスト issue に提案する。提案のみで PR は作らない。/audit-sessions-propose で能動的に呼び出したときのみ動く（自動発火しない）。
disable-model-invocation: true
---

# セッションログ監査（提案）

一定期間のセッションログから人間の発話だけを抽出し、
「繰り返し手打ちしている定型手順」「毎回口頭で補っているルール」
「コードに対して繰り返している同じ指摘」「プロンプトの書き方の癖」を洗い出す。

**目的は、散文ルール・口頭指示・人間や LLM の都度判断に頼っていた改善を、決定論的に強制・ハーネスできる仕組み（linter・hook・スクリプト・CI・型制約）へ移せる箇所を増やすこと。**
出力の 4 カテゴリはその移し先で固定する:
**スキル化候補 / 設定・ルール化候補 / lint ルール化候補 / プロンプト改善**。

強制力は「散文ルール → スキル → hook → linter」の順で上がり、右へ行くほど決定論的になる。
決定論的に判定できる規約（AST で静的に判定できるコード規約など）は
lint ルール化候補へ回し、散文（CLAUDE.md）や口頭指示に留めない。

**このスキルは提案（監査 issue の作成・更新）まで。PR は作らない。**
チェック承認後の実装は audit-sessions-apply-approved が担う。

## 0. 期間の指定

引数（`$ARGUMENTS`）で分析期間を決める。全ログを毎回読まず、定期実行できるようにする。

- 引数なし → 直近 **7 日**（デフォルト）
- `1w` / `1week` / `7` / `7d` → 直近 7 日
- `2w` → 直近 14 日
- `1m` / `1month` / `30` → 直近 30 日
- `3m` → 直近 90 日
- `all` / `0` → 全期間
- `YYYY-MM-DD..YYYY-MM-DD` → 明示範囲（開始..終了）

macOS の BSD `date` で開始日を解決する（このリポジトリの実行環境は darwin）。

```bash
# 例: 直近 7 日
START="$(date -v-7d +%Y-%m-%d)"; END="$(date -v+1d +%Y-%m-%d)"
# 例: 直近 1 ヶ月   START="$(date -v-1m +%Y-%m-%d)"
# 例: 全期間        START を空にして find の -newermt "$START" 条件を外す
# 例: 明示範囲      START=2026-07-01 END=2026-07-13
```

END は「終了日の翌日 0 時より前」を境界にするため、既定では明日（`date -v+1d`）を使う。
解決した期間はレポート冒頭に必ず記録する（定期実行の突合のため）。

## 対象オーナーの限定

分析対象は次のオーナーのリポジトリに限る（allowlist）:
`kokoichi206` / `kokoichi206-sandbox` / `Wareware-PJ`。
audit-sessions-apply-approved の対象リポ allowlist と揃えること。

セッションログのディレクトリ名はプロジェクト絶対パスの `/`・`.` を `-` に置換したもので、
ghq 管理のリポジトリは `...-github-com-<owner>-<repo>` を含む。allowlist のオーナーで絞る:

```bash
OWNERS='github-com-kokoichi206|github-com-Wareware-PJ'
# github-com-kokoichi206 は kokoichi206 と kokoichi206-sandbox の両方に前方一致する
# （どちらも allowlist 内なので個別列挙は不要）。
```

- ghq 外（`orca-workspaces` / `work` 配下の worktree など）はパスにオーナーが出ないため、
  対象オーナーの worktree を取りこぼしうる。精度が要るときは encoded path をデコードして
  実ディレクトリの `git remote get-url origin` でオーナーを確認する。

## 1. 対象セッションを列挙する

- セッション jsonl は `~/.claude/projects/<encoded-path>/<session-id>.jsonl`。
- **`<project>/<session-id>/subagents/` 配下はサブエージェントのログなので除外する。**
  `-maxdepth 2` で glob をトップレベルに限定すれば除外できる。
- 「対象オーナーの限定」の allowlist で encoded path を絞る。

```bash
# START / END は §0 で解決した値。全期間のときは -newermt "$START" を外す。
# mtime は事前絞り込みにすぎない（START 以降に更新のないファイルは対象発話を含み得ない）。
# 上限は付けない: 期間指定監査でも書き込み継続中のセッションを取りこぼさないため。
# 期間の確定は §2 の発話 timestamp フィルタで行う。
find ~/.claude/projects -maxdepth 2 -name '*.jsonl' \
  -newermt "$START" \
  | grep -E "$OWNERS" | sort
```

- 列挙結果が 0 件なら「対象期間にセッションなし」と報告して終了する（空の分析を回さない）。

## 2. 人間発話のみを抽出する

- 抽出条件: `.type == "user"` かつ sidechain でない、**かつ発話 `.timestamp` が期間内**。
  長寿セッション（数週間書き込みが続く jsonl）は mtime が新しくても古い発話を含むため、
  timestamp で絞らないと期間外の摩擦を「直近」と誤認する（経費精算スキルで実際に誤検出した）。
  timestamp は UTC の ISO8601 なので START/END（ローカル日付）との比較は文字列比較でよいが、
  日界は最大 9 時間ずれる。境界日の数件のずれは許容する。
  `content` は string または block 配列（配列は `.type == "text"` のみ採用。`tool_result` は除外される）。
- ノイズ除去: スキル展開（`<command-name>` / `<local-command-stdout>`）、`Caveat:` で始まる注記、
  `<system-reminder>` ブロックを除去する。
- 1 発話 600 字に切り詰める（長大な diff 貼り付け等で分析用コーパスが溢れるのを防ぐ）。

```bash
jq -r --arg start "$START" --arg end "$END" '
  select(.type == "user" and ((.isSidechain // false) | not))
  | select((.timestamp // "") >= $start and (.timestamp // "") < $end)
  | .message.content
  | if type == "string" then . else (map(select(.type == "text") | .text // empty) | join("\n")) end
  | select(length > 0)
  | select(startswith("Caveat:") | not)
  | gsub("<system-reminder>[\\s\\S]*?</system-reminder>"; "")
  | select(test("<command-name>|<local-command-stdout>") | not)
  | gsub("^\\s+|\\s+$"; "")
  | select(length > 0)
  | .[0:600] + "\n---"
' <file>.jsonl
```

- ファイルごとにヘッダ（プロジェクト名・session-id・日付）を付けて 1 コーパスに連結する。
  日付はファイル mtime でなく**フィルタ後の発話 timestamp の範囲**（最初と最後）を使う。
- timestamp フィルタ後に発話が 0 件になったファイルはコーパスに含めない。
- lint ルール化候補はプロジェクトと言語に紐づくため、
  **どの発話がどのプロジェクトのものか**（ヘッダのプロジェクト名）を分析まで保持する。

## 3. バケットに分割する

- プロジェクト単位でグルーピングし、量が偏らないよう数バケットに分割する
  （関連プロジェクトは同じバケットに入れると文脈横断のパターンを拾いやすい）。

## 4. バケットごとに並列エージェントで分析する

各エージェントへの指示に含めること:

- 出力カテゴリを 4 つに固定する。各候補に **出現回数** と
  **代表発話の引用（1〜2 個、原文まま）** を必ず付ける。引用のない候補は採用しない。
- 1 回しか出ていないものは「候補」ではなく「観察」として分ける。

### カテゴリ別の判定基準

1. **スキル化候補**: ほぼ同一文面で繰り返される複数手順の定型作業（例: レビュー収束→PR）。
2. **設定・ルール化候補**: 毎回口頭で補っている運用規約や、機械的な失敗の再発防止。
   落とす先を明示する: `CLAUDE.md`（散文の運用原則）/ path-scoped rule（特定パス編集時）/
   `settings.json`（permission・env）/ hook（PreToolUse/Stop 等で強制）。
3. **lint ルール化候補**: **コードに対して繰り返している同じ指摘**を、
   AST ベースの linter（eslint / ktlint / その他言語の linter）ルールに落とせるもの。
   - 判定基準は「AST で静的に判定できるか」。命名規約・禁止 API・禁止パターン・import 順・
     マジックナンバー・any 濫用など、コード構造から機械判定できるものだけをここに入れる。
     文脈依存で静的判定できない指摘は 2（設定・ルール化）へ回す。
   - 各候補に必ず付ける: **対象リポジトリと言語** / 既存ルール名（あれば eslint・ktlint の
     ルール ID）または自作ルールの要否 / ルール設定のドラフト（1〜数行）。
   - ソースは人間の**コードへの訂正発話**（例: 「また any 使ってる」「この命名やめて」
     「マジックナンバー直して」「import の順序」）。訂正が同一リポジトリで反復しているものを拾う。
4. **プロンプト改善**: 対象未特定・完了条件後出しなど、ユーザーの指示の出し方で減らせる摩擦。

## 5. 統合して報告する

- バケット横断で同一パターンをマージし、出現回数を合算する。
- **既知事項の除外**（二重に読む）:
  - 過去監査の結論をメモリ（`~/.claude/projects/<project>/memory/MEMORY.md` と配下のノート）から読む。
  - lint ルール化候補は、対象リポジトリに**そのルールが既に設定済みでないか**を確認する
    （`.eslintrc*` / `eslint.config.*` / `.golangci.yml` / `ktlint`・`detekt` 設定 / `biome.json` 等）。
    既に有効なルールは報告しない。
- レポート冒頭に **分析期間（解決済みの START..END）と対象セッション数** を記載する。
- 各候補に「次のアクション」を 1 つ添える:
  スキル名案 / ルール文案 / lint ルール ID + 設定ドラフト + 対象リポジトリ / 確認事項。
- レポートは日本語で `reports/audit-sessions-<END>.md` に書き出す（定期実行の履歴として残す）。
- 定期実行の通知・承認入口として dotfiles に「セッション監査 <END>」issue を 1 件立てる
  （既存のオープンな監査 issue があれば追記更新）。
- 監査 issue の本文は **候補 1 件 = タスクリスト 1 行**で書く。
  このチェックボックスが audit-sessions-apply-approved の承認ゲートになる
  （チェックされた行だけが実装される）。形式を変えるときは両スキルで揃えること:

  ```markdown
  - [ ] lint: <要約> (repo: <owner>/<repo>, 出現 N 回)
  - [ ] hook: <要約> (repo: dotfiles, 出現 N 回)
  ```

  各行に reports のパスと該当セクションへの参照を添え、詳細はレポート側に置く。
