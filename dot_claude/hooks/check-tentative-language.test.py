#!/usr/bin/env python3
"""
check-tentative-language.py の単体テスト。標準ライブラリ unittest のみ（依存なし）。

実行: python3 check-tentative-language.test.py
      (dotfiles repo からは `make test-claude-hooks`)

transcript の実形式（{"type": "assistant", "message": {...}} の入れ子）を読めること、
留保表現を block すること、block 後の再実行で再ブロックしないことを固定する。
hook は判定不能なら通す fail open なので、読めない形式は「無言で素通り」になる。
その素通りが検出漏れと区別できないため、形式の固定をテストで持つ。
"""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest

_HERE = os.path.dirname(os.path.abspath(__file__))
_SCRIPT = os.path.join(_HERE, "check-tentative-language.py")

# ハイフン入りファイル名は通常 import 不可のため importlib で読む。
_spec = importlib.util.spec_from_file_location("checker", _SCRIPT)
checker = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(checker)


def nested_entry(text):
    """Claude Code が transcript に書く実際の形式。"""
    return {
        "type": "assistant",
        "message": {"role": "assistant", "content": [{"type": "text", "text": text}]},
    }


def run_hook(entries, stop_hook_active=False):
    """transcript を作って hook を実行し、(stdout, returncode) を返す。"""
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".jsonl", delete=False, encoding="utf-8"
    ) as f:
        for e in entries:
            f.write(json.dumps(e, ensure_ascii=False) + "\n")
        path = f.name
    try:
        payload = json.dumps(
            {"transcript_path": path, "stop_hook_active": stop_hook_active}
        )
        r = subprocess.run(
            [sys.executable, _SCRIPT],
            input=payload,
            capture_output=True,
            text=True,
        )
        return r.stdout.strip(), r.returncode
    finally:
        os.unlink(path)


class TestExtractAssistantText(unittest.TestCase):
    def test_reads_nested_transcript_format(self):
        self.assertEqual(
            checker.extract_assistant_text(nested_entry("こんにちは")), "こんにちは"
        )

    def test_reads_flat_format(self):
        entry = {"role": "assistant", "content": "こんにちは"}
        self.assertEqual(checker.extract_assistant_text(entry), "こんにちは")

    def test_joins_multiple_text_blocks(self):
        entry = {
            "type": "assistant",
            "message": {
                "role": "assistant",
                "content": [
                    {"type": "text", "text": "前半"},
                    {"type": "tool_use", "name": "Bash"},
                    {"type": "text", "text": "後半"},
                ],
            },
        }
        self.assertEqual(checker.extract_assistant_text(entry), "前半 後半")

    def test_ignores_user_entries(self):
        entry = {"type": "user", "message": {"role": "user", "content": "一旦これで"}}
        self.assertIsNone(checker.extract_assistant_text(entry))


class TestBlockDecision(unittest.TestCase):
    def test_blocks_on_tentative_expression(self):
        stdout, code = run_hook([nested_entry("一旦こうしておきます。")])
        self.assertEqual(code, 0)
        out = json.loads(stdout)
        self.assertEqual(out["decision"], "block")
        self.assertIn("一旦", out["reason"])

    def test_reports_every_matched_expression(self):
        stdout, _ = run_hook([nested_entry("とりあえず直して、ひとまず様子を見ます。")])
        reason = json.loads(stdout)["reason"]
        self.assertIn("とりあえず", reason)
        self.assertIn("ひとまず", reason)

    def test_passes_clean_output(self):
        stdout, code = run_hook([nested_entry("原因は設定漏れでした。修正済みです。")])
        self.assertEqual(stdout, "")
        self.assertEqual(code, 0)

    def test_inspects_only_latest_assistant_message(self):
        stdout, _ = run_hook(
            [nested_entry("一旦こうします。"), nested_entry("結論はこうです。")]
        )
        self.assertEqual(stdout, "")

    def test_does_not_reblock_when_stop_hook_active(self):
        stdout, _ = run_hook([nested_entry("一旦こうします。")], stop_hook_active=True)
        self.assertEqual(stdout, "")

    def test_skips_malformed_lines(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".jsonl", delete=False, encoding="utf-8"
        ) as f:
            f.write(json.dumps(nested_entry("一旦こうします。"), ensure_ascii=False) + "\n")
            f.write("{壊れた行\n")
            path = f.name
        try:
            payload = json.dumps({"transcript_path": path, "stop_hook_active": False})
            r = subprocess.run(
                [sys.executable, _SCRIPT], input=payload, capture_output=True, text=True
            )
            self.assertEqual(json.loads(r.stdout)["decision"], "block")
        finally:
            os.unlink(path)


class TestFailOpen(unittest.TestCase):
    def test_passes_when_transcript_missing(self):
        payload = json.dumps(
            {"transcript_path": "/nonexistent/transcript.jsonl", "stop_hook_active": False}
        )
        r = subprocess.run(
            [sys.executable, _SCRIPT], input=payload, capture_output=True, text=True
        )
        self.assertEqual(r.stdout.strip(), "")
        self.assertEqual(r.returncode, 0)

    def test_passes_on_invalid_stdin(self):
        r = subprocess.run(
            [sys.executable, _SCRIPT], input="not json", capture_output=True, text=True
        )
        self.assertEqual(r.stdout.strip(), "")
        self.assertEqual(r.returncode, 0)


if __name__ == "__main__":
    unittest.main()
