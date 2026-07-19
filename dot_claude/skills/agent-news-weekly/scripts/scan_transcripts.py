#!/usr/bin/env python3
"""Claude Code transcript を集計し、週次ニュースの「実測」判定の材料を出す。

~/.claude/projects 直下 1 階層の *.jsonl のみ対象 (sidechain ファイルは除外)。
output_tokens は usage の合算で thinking を含む概算。
"""
import argparse
import json
import os
import re
import time
from collections import Counter, defaultdict

CMD_RE = re.compile(r"<command-name>([^<]+)</command-name>")
REVIEW_SKILLS = {
    "code-review", "verify", "multi-reviewer",
    "kk-dev:review-detailed", "simplify", "code-simplifier:code-simplifier",
}


def bucket(values):
    bounds = [(0, 0), (1, 10), (11, 50), (51, 100), (101, 200), (201, None)]
    out = Counter()
    for v in values:
        for lo, hi in bounds:
            if hi is None:
                if v >= lo:
                    out[f"{lo}+"] += 1
                    break
            elif lo <= v <= hi:
                out[f"{lo}-{hi}"] += 1
                break
    return dict(out)


def scan(days):
    root = os.path.expanduser("~/.claude/projects")
    cutoff = time.time() - days * 86400
    files = [
        os.path.join(root, d, f)
        for d in os.listdir(root)
        if os.path.isdir(os.path.join(root, d))
        for f in os.listdir(os.path.join(root, d))
        if f.endswith(".jsonl") and os.path.getmtime(os.path.join(root, d, f)) > cutoff
    ]

    proj = defaultdict(Counter)
    per_file = []
    skill_names = Counter()
    cmd_names = Counter()
    review_auto = Counter()
    review_explicit = Counter()
    sidechains = 0

    for path in files:
        project = os.path.basename(os.path.dirname(path))
        counts = Counter()
        file_cmds = set()
        sidechain = False
        with open(path, errors="replace") as fh:
            for i, line in enumerate(fh):
                if i == 0 and '"isSidechain":true' in line:
                    sidechain = True
                if "<command-name>" in line:
                    for m in CMD_RE.findall(line):
                        cmd_names[m.strip()] += 1
                        file_cmds.add(m.strip().lstrip("/"))
                if '"tool_use"' not in line and '"output_tokens"' not in line:
                    continue
                try:
                    d = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if d.get("type") != "assistant":
                    continue
                msg = d.get("message") or {}
                counts["out_tok"] += (msg.get("usage") or {}).get("output_tokens", 0) or 0
                for block in msg.get("content") or []:
                    if not (isinstance(block, dict) and block.get("type") == "tool_use"):
                        continue
                    name = block.get("name", "")
                    if name in ("Agent", "Task"):
                        counts["spawn"] += 1
                    elif name == "WebSearch":
                        counts["websearch"] += 1
                    elif name == "Skill":
                        sk = (block.get("input") or {}).get("skill", "?")
                        skill_names[sk] += 1
                        if sk in REVIEW_SKILLS:
                            target = review_explicit if sk.lstrip("/") in file_cmds else review_auto
                            target[sk] += 1
        if sidechain:
            sidechains += 1
            continue
        proj[project].update(
            {"files": 1, "out_tok": counts["out_tok"], "spawn": counts["spawn"], "websearch": counts["websearch"]}
        )
        per_file.append((counts["spawn"], counts["websearch"], counts["out_tok"], project, os.path.basename(path)))

    spawns = [x[0] for x in per_file]
    searches = [x[1] for x in per_file]
    print(f"対象: {len(files)} ファイル / 本セッション {len(per_file)} / sidechain 除外 {sidechains}")
    print("subagent spawn 分布:", bucket(spawns), "/ 最大:", max(spawns, default=0))
    print("WebSearch 分布:", bucket(searches), "/ 最大:", max(searches, default=0))
    print("レビュー系 skill 自動発火:", dict(review_auto) or 0, "/ 明示:", dict(review_explicit) or 0)
    print("skill 発火 top15:", skill_names.most_common(15))
    print("明示コマンド top15:", cmd_names.most_common(15))
    print(f"出力トークン合計 ({days}日):", sum(x[2] for x in per_file))
    print("プロジェクト別 (sessions, spawn, websearch, out_tok):")
    rows = sorted(
        ((v["files"], v["spawn"], v["websearch"], v["out_tok"], k) for k, v in proj.items()),
        reverse=True,
    )
    for row in rows[:12]:
        print("   ", row)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--days", type=int, default=7)
    scan(parser.parse_args().days)
