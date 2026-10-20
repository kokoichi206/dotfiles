# /// script
# requires-python = ">=3.11"
# dependencies = ["tomlkit==0.13.3"]
# ///
"""Merge shared Codex settings while preserving local settings and comments."""

import argparse
from collections.abc import MutableMapping
from datetime import datetime
import os
from pathlib import Path
import shutil
import tempfile

import tomlkit


def merge_common_settings(target, common):
    for key, value in common.items():
        if isinstance(value, MutableMapping) and isinstance(
            target.get(key), MutableMapping
        ):
            merge_common_settings(target[key], value)
        else:
            target[key] = value


def apply_config(common_path: Path, target_path: Path, *, check: bool = False) -> bool:
    if target_path.is_symlink():
        raise ValueError(f"Refusing to replace a symlink: {target_path}")

    common = tomlkit.parse(common_path.read_text())
    original = target_path.read_text() if target_path.exists() else ""
    target = tomlkit.parse(original)
    original_settings = target.unwrap()
    merge_common_settings(target, common)
    if original_settings == target.unwrap():
        return False

    rendered = tomlkit.dumps(target)
    if check:
        return True

    target_path.parent.mkdir(parents=True, exist_ok=True)
    if target_path.exists():
        stamp = datetime.now().strftime("%Y%m%d%H%M%S%f")
        backup = target_path.with_name(f"{target_path.name}.before-common-{stamp}")
        shutil.copy2(target_path, backup)
        print(f"Backup: {backup}")

    # 置き換え前に書き切り、認証情報を含むファイルを他ユーザーに公開しない。
    with tempfile.NamedTemporaryFile(
        mode="w", dir=target_path.parent, prefix=".codex-config-", delete=False
    ) as temporary:
        temporary.write(rendered)
        temporary_path = Path(temporary.name)
    temporary_path.replace(target_path)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Exit 1 if changes are pending")
    parser.add_argument(
        "--target",
        type=Path,
        default=Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")) / "config.toml",
    )
    args = parser.parse_args()
    changed = apply_config(
        Path(__file__).with_name("config.common.toml"), args.target, check=args.check
    )
    if args.check:
        print("Common settings differ" if changed else "Common settings are up to date")
        return int(changed)
    print(f"{'Applied' if changed else 'Already up to date'}: {args.target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
