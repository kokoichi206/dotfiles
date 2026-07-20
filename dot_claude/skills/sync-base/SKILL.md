---
name: sync-base
description: PR マージ後に最新 base から次の作業ブランチを切って開始する手順。detached HEAD を作らない。トリガー - merge した, merge した次, merge したので次, マージした, マージしちゃった, fetch して develop から, fetch して main から, base 同期, 次のブランチ, マージ後の同期
---

# base 同期・次ブランチ開始

PR をマージしたあと、最新の base を取り込んで次の作業ブランチを切る。
**detached HEAD を作らない**ことが要点。

## 原則

- **`git switch -c <新ブランチ> origin/<base>` で新ブランチを切る。**
- `git checkout $(git rev-parse origin/<base>)` のような **commit 直指定はしない**。
  detached HEAD になり、以降のコミット・PR 作成連鎖が失敗する原因になる。

## 手順

1. **base を特定する**
   - repo の `CLAUDE.md` / `AGENTS.md` の規約に従う。無ければ default branch。

     ```bash
     gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
     ```

2. **直前 PR がマージ済みか確認する**
   - 前の作業がマージされて base に入っていることを確かめてから同期する。

     ```bash
     gh pr view <前の PR 番号> --json state,mergedAt
     ```

3. **最新を取得する**

   ```bash
   git fetch origin
   ```

4. **base から新ブランチを切る**
   - 新ブランチ名は次タスクに沿った kebab-case で付ける。

     ```bash
     git switch -c <feat/次タスク> origin/<base>
     ```

5. **起点を確認して次タスクへ**
   - detached HEAD になっていないこと、base の最新に乗っていることを確認する。

     ```bash
     git status          # "On branch <feat/次タスク>" であること（HEAD detached でない）
     git log --oneline -1 origin/<base>
     ```
