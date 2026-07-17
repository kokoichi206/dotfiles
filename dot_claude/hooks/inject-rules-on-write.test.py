#!/usr/bin/env python3
"""
inject-rules-on-write.py の単体テスト。標準ライブラリ unittest のみ（依存なし）。

実行: python3 inject-rules-on-write.test.py
      (dotfiles repo からは `make test-claude-hooks`)

glob セマンティクス（* は 1 セグメント / ** は任意階層 / brace 展開）と
「Write の新規作成時だけ注入・既存ファイルは skip」という穴埋め挙動を固定する。
"""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest

_HERE = os.path.dirname(os.path.abspath(__file__))
_SCRIPT = os.path.join(_HERE, "inject-rules-on-write.py")

# ハイフン入りファイル名は通常 import 不可のため importlib で読む。
_spec = importlib.util.spec_from_file_location("injector", _SCRIPT)
injector = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(injector)


class TestGlobMatching(unittest.TestCase):
    def test_star_is_single_segment(self):
        self.assertTrue(injector.path_matches("*/go.mod", "backend/go.mod"))
        self.assertFalse(injector.path_matches("*/go.mod", "apps/backend/go.mod"))
        self.assertFalse(injector.path_matches("*/go.mod", "go.mod"))

    def test_doublestar_is_any_depth(self):
        self.assertTrue(injector.path_matches("**/go.mod", "go.mod"))
        self.assertTrue(injector.path_matches("**/go.mod", "apps/backend/go.mod"))
        self.assertTrue(injector.path_matches("**/go.mod", "a/b/c/go.mod"))

    def test_root_only_pattern(self):
        self.assertTrue(injector.path_matches("*.md", "README.md"))
        self.assertFalse(injector.path_matches("*.md", "docs/README.md"))

    def test_doublestar_extension(self):
        self.assertTrue(injector.path_matches("**/*.md", "README.md"))
        self.assertTrue(injector.path_matches("**/*.md", "docs/a/README.md"))

    def test_middle_single_segment(self):
        self.assertTrue(
            injector.path_matches("infra/terraform/*/version.tf", "infra/terraform/prod/version.tf")
        )
        self.assertFalse(
            injector.path_matches("infra/terraform/*/version.tf", "infra/terraform/a/b/version.tf")
        )

    def test_brace_expansion(self):
        pat = "src/api/**/*.{ts,tsx}"
        self.assertTrue(injector.path_matches(pat, "src/api/handler.ts"))
        self.assertTrue(injector.path_matches(pat, "src/api/users/handler.tsx"))
        self.assertFalse(injector.path_matches(pat, "src/other/handler.ts"))

    def test_no_partial_match(self):
        self.assertFalse(injector.path_matches("*.md", "README.md.bak"))
        self.assertFalse(injector.path_matches("go.mod", "app/go.mod"))


class TestExpandBraces(unittest.TestCase):
    def test_single(self):
        self.assertEqual(injector.expand_braces("a{b,c}d"), ["abd", "acd"])

    def test_no_brace(self):
        self.assertEqual(injector.expand_braces("abc"), ["abc"])

    def test_multiple_groups(self):
        self.assertEqual(injector.expand_braces("{a,b}/{c,d}"), ["a/c", "a/d", "b/c", "b/d"])


class TestFrontmatter(unittest.TestCase):
    def test_extract_paths(self):
        content = '---\npaths:\n  - "*.md"\n  - "src/**/*.ts"\n---\nbody here'
        self.assertEqual(injector.parse_frontmatter(content), ["*.md", "src/**/*.ts"])

    def test_no_frontmatter(self):
        self.assertEqual(injector.parse_frontmatter("# just a doc\ncontent"), [])

    def test_frontmatter_without_paths(self):
        self.assertEqual(injector.parse_frontmatter("---\ntitle: x\n---\nbody"), [])

    def test_rule_body_strips_frontmatter(self):
        content = "---\npaths:\n  - x\n---\n\n# Title\ntext"
        self.assertEqual(injector.rule_body(content), "# Title\ntext")


class TestEndToEnd(unittest.TestCase):
    """hermetic な temp git repo で「Write 新規作成の穴埋め」挙動を検証する。"""

    def _run(self, payload: dict, cwd: str) -> str:
        env = dict(os.environ)
        # user スコープ (~/.claude/rules) を temp HOME で無効化し project スコープだけ見る。
        env["HOME"] = cwd
        r = subprocess.run(
            [sys.executable, _SCRIPT],
            input=json.dumps(payload),
            capture_output=True, text=True, cwd=cwd, env=env,
        )
        return r.stdout.strip()

    def _make_repo(self) -> str:
        d = os.path.realpath(tempfile.mkdtemp())
        subprocess.run(["git", "init", "-q"], cwd=d, check=True)
        rules_dir = os.path.join(d, ".claude", "rules")
        os.makedirs(rules_dir)
        with open(os.path.join(rules_dir, "mise.md"), "w") as f:
            f.write('---\npaths:\n  - ".mise.toml"\n  - "**/go.mod"\n---\n# mise rule\nsync check.')
        return d

    def test_write_new_file_injects(self):
        d = self._make_repo()
        out = self._run(
            {"tool_name": "Write", "tool_input": {"file_path": os.path.join(d, ".mise.toml")}}, d
        )
        self.assertIn("mise rule", out)
        self.assertEqual(json.loads(out)["hookSpecificOutput"]["hookEventName"], "PreToolUse")

    def test_write_existing_file_no_inject(self):
        # 既存ファイルへの Write は標準機構がカバー済 → skip
        d = self._make_repo()
        target = os.path.join(d, ".mise.toml")
        with open(target, "w") as f:
            f.write("existing")
        out = self._run({"tool_name": "Write", "tool_input": {"file_path": target}}, d)
        self.assertEqual(out, "")

    def test_read_is_not_handled(self):
        # Read は標準機構がカバーするので hook は何もしない
        d = self._make_repo()
        out = self._run(
            {"tool_name": "Read", "tool_input": {"file_path": os.path.join(d, ".mise.toml")}}, d
        )
        self.assertEqual(out, "")

    def test_edit_is_not_handled(self):
        # Edit は事前 Read 必須 = 標準機構がカバー → hook は何もしない
        d = self._make_repo()
        out = self._run(
            {"tool_name": "Edit", "tool_input": {"file_path": os.path.join(d, "apps/x/go.mod")}}, d
        )
        self.assertEqual(out, "")

    def test_no_match_no_output(self):
        d = self._make_repo()
        out = self._run(
            {"tool_name": "Write", "tool_input": {"file_path": os.path.join(d, "README.md")}}, d
        )
        self.assertEqual(out, "")

    def test_nested_new_gomod_injects(self):
        d = self._make_repo()
        out = self._run(
            {"tool_name": "Write", "tool_input": {"file_path": os.path.join(d, "apps/backend/go.mod")}},
            d,
        )
        self.assertIn("mise rule", out)


if __name__ == "__main__":
    unittest.main(verbosity=2)
