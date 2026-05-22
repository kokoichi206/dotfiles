#!/bin/bash
# PreCompact hook: snapshot session state into the workspace memory/ before compaction.
# Workspace dir convention: /Users/.../.claude/projects/<cwd-with-slashes-and-dots-replaced-by-dashes>/memory/

set -euo pipefail

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

[ -z "$cwd" ] && exit 0

workspace=$(echo "$cwd" | tr '/.' '-')
memory_dir="$HOME/.claude/projects/$workspace/memory"
mkdir -p "$memory_dir"

timestamp=$(date +%Y-%m-%dT%H-%M-%S)
out="$memory_dir/compact-$timestamp.md"

branch=""
if (cd "$cwd" && git rev-parse --git-dir > /dev/null 2>&1); then
    branch=$(cd "$cwd" && git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
fi

cat > "$out" <<EOF
---
name: compact-$timestamp
description: PreCompact 時のスナップショット ($branch)
metadata:
  type: snapshot
  cwd: $cwd
  branch: $branch
  at: $(date -Iseconds)
---

# Pre-Compact Snapshot

このセッションは context compaction を経た。圧縮前の状態:

- cwd: $cwd
- branch: $branch
- timestamp: $(date -Iseconds)
EOF

if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    prompts=$(jq -r '
        select(.type == "user" and (.message.content | type) == "string")
        | .message.content
    ' "$transcript_path" 2>/dev/null | grep -v '^$' | tail -5 || true)
    if [ -n "$prompts" ]; then
        {
            echo ""
            echo "## 圧縮前の直近 user prompt (最大 5 件)"
            echo ""
            echo "$prompts" | sed 's/^/- /'
        } >> "$out"
    fi
fi

exit 0
