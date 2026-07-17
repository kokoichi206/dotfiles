#!/usr/bin/env python3
"""
PreToolUse guard: gh pr create/edit のタイトル言語をリポジトリの言語ポリシーと照合する。

ポリシーはリポジトリルートの .claude/pr-lang で指定する (ja / en / any)。
未指定のリポジトリは ja とみなす。
タイトルを静的に判定できない入力 (コマンド置換など) は exit 0 で通常フローに委ねる (fail open)。
"""
import json
import re
import subprocess
import sys
from pathlib import Path

TITLE_RE = re.compile(r"(?:--title|-t)(?:=|\s+)(?:'([^']*)'|\"([^\"]*)\"|(\S+))")
JA_CHAR_RE = re.compile(r"[぀-ヿ一-鿿]")


def deny(reason: str) -> None:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }, ensure_ascii=False))
    sys.exit(0)


def expected_lang(cwd: str) -> str:
    root = cwd
    try:
        result = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=5,
        )
        if result.returncode == 0 and result.stdout.strip():
            root = result.stdout.strip()
    except Exception:
        pass

    conf = Path(root) / ".claude" / "pr-lang"
    if conf.is_file():
        value = conf.read_text(encoding="utf-8").strip().lower()
        if value in ("ja", "en", "any"):
            return value
    return "ja"


def main() -> None:
    try:
        hook_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    if hook_input.get("tool_name") != "Bash":
        sys.exit(0)

    command = hook_input.get("tool_input", {}).get("command", "")
    if not re.search(r"gh\s+pr\s+(create|edit)\b", command):
        sys.exit(0)

    match = TITLE_RE.search(command)
    if not match:
        sys.exit(0)
    title = next(g for g in match.groups() if g is not None)

    # コマンド置換・変数展開を含むタイトルは実行前に値が確定しないため判定しない
    if any(marker in title for marker in ("$(", "`", "${")):
        sys.exit(0)

    lang = expected_lang(hook_input.get("cwd", "."))
    if lang == "any":
        sys.exit(0)

    has_ja = bool(JA_CHAR_RE.search(title))
    if lang == "ja" and not has_ja:
        deny(
            f"PR タイトルは日本語で書くこと (現在: {title})。"
            "このリポジトリが英語タイトル運用なら .claude/pr-lang に en を置く。"
        )
    if lang == "en" and has_ja:
        deny(
            f"このリポジトリの PR タイトルは英語で書くこと (.claude/pr-lang=en, 現在: {title})。"
        )

    sys.exit(0)


if __name__ == "__main__":
    main()
