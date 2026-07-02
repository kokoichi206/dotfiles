---
paths:
  - "**/CLAUDE.md"
  - "**/AGENTS.md"
---

# CLAUDE.md / AGENTS.md 編集ガイド

`CLAUDE.md` / `AGENTS.md` を編集・新規作成するときに従う。

- **開発に必要な非自明情報だけを書く。** そのリポで作業する人（や Claude）が
  コードを読んでも分からない前提・規約・ハマりどころを書く。
- **コード・`package.json` から分かることは書かない。** スクリプト名・ディレクトリ構成・
  自明なコマンドは書かない（コードが正。ドキュメントに複製すると変更に追従できずドリフトする）。
- **目安 70 行以下。** 長くなるなら、静的に効かせたいルールは `paths` 付きの
  path-specific rule（`.claude/rules/`）へ、手順は skill へ分割する。
- **変更前に公式ドキュメントを確認する**: memory / CLAUDE.md の仕様を最新で確認してから着手する。
  - https://code.claude.com/docs/en/memory
