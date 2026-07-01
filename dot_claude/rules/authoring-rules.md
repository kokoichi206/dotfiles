---
paths:
  - "**/.claude/rules/**/*.md"
  - "**/dot_claude/rules/**/*.md"
---

# Rule ファイル編集ガイド

`.claude/rules/`（このリポジトリの実体は `dot_claude/rules/`）配下の `.md` を
編集・新規作成するときに従う。

- **変更前に公式ドキュメントを通読する**: path-specific rules の仕様を最新で確認してから着手する。
  - https://code.claude.com/docs/en/memory#path-specific-rules
- **`paths` frontmatter で対象を絞る**:
  - YAML frontmatter に `paths` を書いてスコープする。
  - 全ファイルに常時効かせたい場合だけ `paths` を省略する（トップ階層の CLAUDE.md と同等になるので注意）。
