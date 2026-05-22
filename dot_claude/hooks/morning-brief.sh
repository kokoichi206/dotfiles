#!/bin/bash
# SessionStart hook: brief project context for new sessions.
# stdout is injected into Claude's first-turn context and shown in the transcript.

set -euo pipefail

git rev-parse --git-dir > /dev/null 2>&1 || exit 0

printf "## session start context\n"
printf "branch: %s\n" "$(git rev-parse --abbrev-ref HEAD)"

modified=$(git status -s --untracked-files=no | wc -l | tr -d ' ')
if [ "$modified" -gt 0 ]; then
    printf "uncommitted (tracked): %s files\n" "$modified"
    git status -s --untracked-files=no | head -5 | sed 's/^/  - /'
fi

if command -v gh > /dev/null 2>&1; then
    prs=$(gh pr list --assignee @me --limit 5 --json number,title 2>/dev/null || true)
    if [ -n "$prs" ] && [ "$prs" != "[]" ]; then
        printf "\nmy open prs:\n"
        echo "$prs" | jq -r '.[] | "  - #\(.number) \(.title)"'
    fi
fi
