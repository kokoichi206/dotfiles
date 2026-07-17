---
paths:
  - "**/.claude/rules/**/*.md"
  - "**/dot_claude/rules/**/*.md"
---

# Rule ファイル編集ガイド

`.claude/rules/`（このリポジトリの実体は `dot_claude/rules/`）配下の `.md` を
編集・新規作成するときに従う。

## 注入の仕組み

Claude Code 標準の path-scoped rules は Read 時に注入されるが、Write の新規作成時は
注入されない（issue #23478 / #38487、どちらも NOT_PLANNED）。標準機構はそのまま生かし、
`hooks/inject-rules-on-write.py`（PreToolUse(Write) hook）が**新規作成時の穴だけ**を埋める。
Anthropic が Write 対応したら hook を settings.json から外すだけで標準に戻る。

## 書き方

- **`paths` frontmatter で対象を絞る**: YAML frontmatter に `paths` を書く。
  全ファイルに常時効かせたい場合だけ `paths` を省略する（CLAUDE.md と同等になる）。
- **glob 仕様に注意**: `*` は 1 セグメント（`*/go.mod` は `a/go.mod` のみ）、
  `**` は任意階層（`**/go.mod` は `go.mod` も `a/b/go.mod` も）。ブレース展開
  `{ts,tsx}` 対応。ルート直下だけなら `*.md`。この semantics は
  `hooks/inject-rules-on-write.test.py` で固定している。
- **変更前に公式仕様を確認**: https://code.claude.com/docs/en/memory#path-specific-rules
