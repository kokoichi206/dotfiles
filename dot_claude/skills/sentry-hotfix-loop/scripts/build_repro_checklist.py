#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: build_repro_checklist.py <issue_json> <output_md>", file=sys.stderr)
        return 1

    issue_json = Path(sys.argv[1])
    output_md = Path(sys.argv[2])

    issue = json.loads(issue_json.read_text(encoding="utf-8"))

    short_id = issue.get("shortId", "unknown")
    title = issue.get("title", "unknown")
    culprit = issue.get("culprit", "unknown")
    level = issue.get("level", "unknown")
    issue_type = issue.get("type", "error")
    platform = issue.get("platform", "unknown")
    # Sentry API: captureMessage 経由のイベントは type="default" で返る
    is_message = issue_type == "default"

    lines = [
        f"# Repro Checklist: {short_id}",
        "",
        f"- title: {title}",
        f"- level: {level}",
        f"- culprit: {culprit}",
        f"- type: {'message (captureMessage/logger)' if is_message else 'exception'}",
        f"- platform: {platform}",
        "",
        "## 1. Preconditions",
        "- 実行環境（branch, commit, env）を記録する",
        "- 対象機能の feature flag を記録する",
        "",
    ]

    if is_message:
        lines += [
            "## 2. Message 発生箇所の特定",
            f"- [ ] コード内で `{title}` を grep する",
            "- [ ] captureMessage / logger.error の呼び出し元を特定する",
            "- [ ] breadcrumbs からユーザー操作の流れを確認する",
            "",
        ]
    else:
        lines += [
            "## 2. Repro Steps",
            "- [ ] ユーザー操作または API 呼び出しを手順化",
            "- [ ] 期待値と実際の差分を記録",
            "",
        ]

    lines += [
        "## 3. Observation",
    ]
    if is_message:
        lines += [
            "- [ ] メッセージの発生条件を特定",
            "- [ ] breadcrumbs からユーザー操作を追跡",
        ]
    else:
        lines += [
            "- [ ] エラーログ（スタックトレース）",
        ]
    lines += [
        "- [ ] 発生時刻とリクエストID",
        "- [ ] 影響範囲（ユーザー/テナント）",
        "",
        "## 4. Fix Validation",
        "- [ ] 修正前に再現することを確認",
        "- [ ] 修正後に同手順で再現しないことを確認",
        "- [ ] 関連テストを実行",
        "",
        "## 5. Postmortem Notes",
        "- 原因:",
        "- 修正:",
        "- 再発防止:",
    ]

    output_md.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {output_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
