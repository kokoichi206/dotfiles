from pathlib import Path
import os
import stat
import subprocess
import sys
import tempfile
import unittest

import tomlkit

from apply_config import apply_config


class ApplyConfigTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.common = self.root / "common.toml"
        self.target = self.root / "codex" / "config.toml"
        self.common.write_text('''model = "shared-model"
[mcp_servers.aws_mcp]
command = "uvx"
args = ["proxy@1.7.0", "--read-only"]
''')

    def write_local(self, text):
        self.target.parent.mkdir(parents=True, exist_ok=True)
        self.target.write_text(text)

    def test_preserves_credentials_projects_comments_and_unmanaged_servers(self):
        self.write_local('''# Local settings
model = "old-model"
[mcp_servers.aws_mcp]
command = "old-proxy"
args = ["old-argument"]
[mcp_servers.aws_mcp.env]
AWS_PROFILE = "dev"
API_TOKEN = "fixture-secret" # Keep locally
[mcp_servers.private]
command = "/local/server"
[projects."/local/project"]
trust_level = "trusted"
''')
        before = self.target.read_text()
        self.assertTrue(apply_config(self.common, self.target))
        rendered = self.target.read_text()
        actual = tomlkit.parse(rendered)
        self.assertEqual(actual["model"], "shared-model")
        self.assertEqual(actual["mcp_servers"]["aws_mcp"]["args"], ["proxy@1.7.0", "--read-only"])
        self.assertEqual(actual["mcp_servers"]["aws_mcp"]["env"]["API_TOKEN"], "fixture-secret")
        self.assertEqual(actual["mcp_servers"]["aws_mcp"]["env"]["AWS_PROFILE"], "dev")
        self.assertEqual(actual["mcp_servers"]["private"]["command"], "/local/server")
        self.assertEqual(actual["projects"]["/local/project"]["trust_level"], "trusted")
        self.assertIn("# Local settings", rendered)
        self.assertIn("# Keep locally", rendered)
        backups = list(self.target.parent.glob("config.toml.before-common-*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), before)
        self.assertEqual(stat.S_IMODE(self.target.stat().st_mode), 0o600)

    def test_initializes_without_symlink_and_reapplying_does_not_write(self):
        self.assertTrue(apply_config(self.common, self.target))
        self.assertFalse(self.target.is_symlink())
        before = self.target.stat().st_mtime_ns
        self.assertFalse(apply_config(self.common, self.target))
        self.assertEqual(self.target.stat().st_mtime_ns, before)
        self.assertEqual(list(self.target.parent.glob("config.toml.before-common-*")), [])

    def test_check_does_not_create_or_modify_files(self):
        self.assertTrue(apply_config(self.common, self.target, check=True))
        self.assertFalse(self.target.parent.exists())
        self.write_local('model = "local-model"\n')
        before = self.target.read_bytes()
        self.assertTrue(apply_config(self.common, self.target, check=True))
        self.assertEqual(self.target.read_bytes(), before)
        self.assertEqual(list(self.target.parent.glob("config.toml.before-common-*")), [])
        apply_config(self.common, self.target)
        self.assertFalse(apply_config(self.common, self.target, check=True))

    def test_invalid_common_or_local_toml_does_not_modify_target(self):
        for common, local in [('model = [', 'model = "local"'), ('model = "common"', 'model = [')]:
            with self.subTest(common=common, local=local):
                self.common.write_text(common)
                self.write_local(local)
                with self.assertRaises(tomlkit.exceptions.ParseError):
                    apply_config(self.common, self.target)
                self.assertEqual(self.target.read_text(), local)
                self.assertEqual(list(self.target.parent.glob("config.toml.before-common-*")), [])

    def test_symlink_is_rejected_without_changing_its_destination(self):
        self.target.parent.mkdir()
        destination = self.root / "destination.toml"
        destination.write_text('model = "local"')
        self.target.symlink_to(destination)
        with self.assertRaises(ValueError):
            apply_config(self.common, self.target)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(destination.read_text(), 'model = "local"')

    def test_cli_uses_codex_home_and_check_exit_status(self):
        script = Path(__file__).with_name("apply_config.py")
        environment = {**os.environ, "CODEX_HOME": str(self.target.parent)}
        command = [sys.executable, str(script)]
        pending = subprocess.run(command + ["--check"], env=environment, capture_output=True)
        self.assertEqual(pending.returncode, 1, pending.stderr)
        self.assertFalse(self.target.exists())
        applied = subprocess.run(command, env=environment, capture_output=True)
        self.assertEqual(applied.returncode, 0, applied.stderr)
        self.assertTrue(self.target.exists())
        checked = subprocess.run(command + ["--check"], env=environment, capture_output=True)
        self.assertEqual(checked.returncode, 0, checked.stderr)


if __name__ == "__main__":
    unittest.main()
