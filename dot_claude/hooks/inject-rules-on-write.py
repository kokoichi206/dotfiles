#!/usr/bin/env python3
"""
PreToolUse(Write) hook: .claude/rules/ の Write 新規作成時の注入漏れを埋める。

Claude Code 標準の path-scoped rules (.claude/rules/ の paths: frontmatter) は
Claude がファイルを Read したときに注入されるが、Write で新規作成するときは
事前 Read が無いため注入されない（issue #23478 / #38487、どちらも NOT_PLANNED）。
Edit / MultiEdit は事前 Read が必須なので標準機構が既にカバーしている。
つまり穴は「Write による新規ファイル作成」だけ。

この hook はその穴だけを埋める:
  - Write のみを対象とし、対象ファイルが「まだ存在しない」ときだけ注入する
    （既存ファイルへの Write は Read 済のはずで標準機構がカバー、重複回避）。
  - ~/.claude/rules/ (user) と <project>/.claude/rules/ (project) から
    paths: が glob マッチしたルール body を additionalContext で注入する。

Write-only では塞げない残り（Edit/Read を足しても二重注入が増えるだけで割に合わない）:
  - /compact で初回 Read の注入が落ちた後、再 Read せず Edit するケース。
  - Bash でのファイル作成（Write ツールを通らないため hook 不可）。

標準機構はそのまま生かすため .claude/rules/ の名前も symlink も変えない。
Anthropic が Write 対応したら、この hook を settings.json から外すだけで標準に戻る。
"""
import json
import os
import re
import subprocess
import sys


def find_project_root(cwd: str) -> str:
    try:
        r = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, cwd=cwd,
        )
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip()
    except Exception:
        pass
    return cwd


def parse_frontmatter(content: str) -> list[str]:
    """paths: リストを返す。frontmatter / paths が無ければ []。"""
    if not content.startswith("---"):
        return []
    end = content.find("\n---", 3)
    if end == -1:
        return []
    fm = content[3:end]
    paths: list[str] = []
    in_paths = False
    for line in fm.splitlines():
        stripped = line.strip()
        if stripped == "paths:":
            in_paths = True
            continue
        if in_paths:
            if stripped.startswith("- "):
                paths.append(stripped[2:].strip().strip("\"'"))
            elif stripped and not line.startswith((" ", "\t")):
                in_paths = False
    return paths


def rule_body(content: str) -> str:
    if content.startswith("---"):
        end = content.find("\n---", 3)
        if end != -1:
            return content[end + 4:].lstrip("\n").strip()
    return content.strip()


def expand_braces(pattern: str) -> list[str]:
    """a{b,c}d -> [abd, acd]。"""
    m = re.search(r"\{([^{}]*)\}", pattern)
    if not m:
        return [pattern]
    pre, post = pattern[: m.start()], pattern[m.end():]
    results: list[str] = []
    for option in m.group(1).split(","):
        results.extend(expand_braces(pre + option + post))
    return results


def glob_to_regex(pattern: str) -> str:
    i, regex = 0, ""
    n = len(pattern)
    while i < n:
        if pattern[i: i + 3] == "**/":
            regex += "(?:.+/)?"
            i += 3
        elif pattern[i: i + 2] == "**":
            regex += ".*"
            i += 2
        elif pattern[i] == "*":
            regex += "[^/]*"
            i += 1
        elif pattern[i] == "?":
            regex += "[^/]"
            i += 1
        else:
            regex += re.escape(pattern[i])
            i += 1
    return regex


def path_matches(pattern: str, rel_path: str) -> bool:
    for expanded in expand_braces(pattern):
        if re.match("^" + glob_to_regex(expanded) + "$", rel_path):
            return True
    return False


def collect_from_dir(rules_dir: str, rel_path: str) -> list[str]:
    if not os.path.isdir(rules_dir):
        return []
    bodies: list[str] = []
    for root, dirs, files in os.walk(rules_dir):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for fname in sorted(files):
            if not fname.endswith(".md"):
                continue
            try:
                with open(os.path.join(root, fname), encoding="utf-8") as f:
                    content = f.read()
            except Exception:
                continue
            paths = parse_frontmatter(content)
            if not paths:
                continue
            if any(path_matches(p, rel_path) for p in paths):
                bodies.append(rule_body(content))
    return bodies


def main() -> None:
    try:
        data = json.loads(sys.stdin.read())
    except Exception:
        sys.exit(0)

    # Write の新規作成だけが標準機構の穴。Read/Edit/MultiEdit は標準機構がカバー済。
    if data.get("tool_name", "") != "Write":
        sys.exit(0)

    file_path = data.get("tool_input", {}).get("file_path", "")
    if not file_path:
        sys.exit(0)

    if not os.path.isabs(file_path):
        file_path = os.path.join(os.getcwd(), file_path)

    # symlink 経由アクセスで file_path と git toplevel の解決結果がずれると
    # relpath が壊れるため両者を正規化する。
    file_path = os.path.realpath(file_path)

    # 既存ファイルへの Write は Read 済のはずで標準機構が注入済。重複回避のため skip。
    if os.path.exists(file_path):
        sys.exit(0)

    project_root = os.path.realpath(find_project_root(os.getcwd()))
    try:
        rel_path = os.path.relpath(file_path, project_root)
    except ValueError:
        rel_path = file_path
    if rel_path.startswith(".."):
        rel_path = file_path.lstrip("/")

    # user -> project の順で並べ、project が後 (= 高優先) に来るようにする
    bodies = (
        collect_from_dir(os.path.expanduser("~/.claude/rules"), rel_path)
        + collect_from_dir(os.path.join(project_root, ".claude", "rules"), rel_path)
    )
    if not bodies:
        sys.exit(0)

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": "\n\n---\n\n".join(bodies),
        }
    }))


if __name__ == "__main__":
    main()
