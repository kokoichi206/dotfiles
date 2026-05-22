#!/bin/bash
# PostToolUse hook: format file after Edit/Write/MultiEdit.
# Receives PostToolUse JSON on stdin; reads tool_input.file_path.

set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[ -z "$file_path" ] && exit 0
[ ! -f "$file_path" ] && exit 0

# Resolve formatter binary: prefer project-local node_modules/.bin, fall back to PATH.
find_bin() {
    local binary=$1
    if command -v "$binary" > /dev/null 2>&1; then
        echo "$binary"
        return 0
    fi
    local dir
    dir=$(dirname "$file_path")
    while [ "$dir" != "/" ] && [ "$dir" != "." ]; do
        if [ -x "$dir/node_modules/.bin/$binary" ]; then
            echo "$dir/node_modules/.bin/$binary"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

case "$file_path" in
    *.ts|*.tsx|*.js|*.jsx|*.json|*.md|*.css|*.html|*.yml|*.yaml)
        if bin=$(find_bin biome); then
            "$bin" check --write "$file_path" >/dev/null 2>&1 || true
        elif bin=$(find_bin prettier); then
            "$bin" --write "$file_path" >/dev/null 2>&1 || true
        fi
        ;;
    *.py)
        if bin=$(find_bin ruff); then
            "$bin" format "$file_path" >/dev/null 2>&1 || true
        elif bin=$(find_bin black); then
            "$bin" -q "$file_path" >/dev/null 2>&1 || true
        fi
        ;;
    *.go)
        if bin=$(find_bin gofmt); then
            "$bin" -w "$file_path" >/dev/null 2>&1 || true
        fi
        ;;
    *.rs)
        if bin=$(find_bin rustfmt); then
            "$bin" --edition 2021 "$file_path" >/dev/null 2>&1 || true
        fi
        ;;
    *.sh|*.bash)
        if bin=$(find_bin shfmt); then
            "$bin" -w "$file_path" >/dev/null 2>&1 || true
        fi
        ;;
esac

exit 0
