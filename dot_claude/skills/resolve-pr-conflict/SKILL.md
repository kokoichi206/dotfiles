---
name: resolve-pr-conflict
description: PR がコンフリクトしたときに base を取り込んで解消する定型手順。rebase ではなく merge で履歴を保持する。トリガー - pr conflict, pr conflict してる, コンフリクト解消, conflict 解消して, マージできない, conflict してる, conflict しちゃった, mergeable false
---

# PR コンフリクト解消

PR が base とコンフリクトしたときに、**履歴を書き換えず** base を取り込んで解消する。
レビュー済み PR で履歴を壊さないことを最優先する。

## 原則

- **`git rebase` は使わない。`git merge origin/<base>` で取り込む。** rebase は履歴を書き換え、
  レビュー済み PR ではレビューコメントの対応関係を壊し force push を強いる。特にレビュー中/済みの PR では避ける。
- base の force push はしない。merge 解消後は通常の `git push` で足りる。

## 手順

1. **base を特定する**
   - repo の `CLAUDE.md` / `AGENTS.md` にブランチ規約があればそれに従う。
   - 無ければ default branch を使う。

     ```bash
     gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
     ```

2. **最新を取得する**

   ```bash
   git fetch origin
   ```

3. **base を merge で取り込む**

   ```bash
   git merge origin/<base>
   ```

4. **コンフリクトを解消する**
   - 競合ファイルを開き、両者の意図を保って解消する。どちらかを機械的に採用しない。
   - 解消後:

     ```bash
     git add <解消したファイル>
     git commit   # merge commit（メッセージは既定のままで可）
     ```

5. **push する**

   ```bash
   git push
   ```

6. **CI と mergeable を再確認する**
   - push で CI が再実行される。`--watch` で shell を占有せず、バックグラウンド + ポーリングで確認する。

     ```bash
     gh pr view --json mergeable,mergeStateStatus
     gh pr checks
     ```
   - `mergeable` が `MERGEABLE`、CI が green になったら「コンフリクト解消・マージ可能」と報告して指示を待つ（自律マージはしない）。
