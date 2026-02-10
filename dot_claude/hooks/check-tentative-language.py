#!/usr/bin/env python3
"""
Stop hook: アシスタントの出力から不確実な言葉を検出し、再考を促す。
"""
import json
import sys
import re
from pathlib import Path

TENTATIVE_PATTERNS = [
    r"とりあえず",
    r"一旦",
    r"ひとまず",
    r"さしあたり",
    r"取り急ぎ",
]

def main():
    try:
        hook_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    transcript_path = hook_input.get('transcript_path', '')

    if not transcript_path or not Path(transcript_path).exists():
        sys.exit(0)

    # 会話履歴から最新のアシスタント出力を取得
    try:
        with open(transcript_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception:
        sys.exit(0)

    text = ""
    for line in reversed(lines):
        try:
            entry = json.loads(line)
            if entry.get('role') == 'assistant':
                content = entry.get('content', '')
                if isinstance(content, str):
                    text = content
                elif isinstance(content, list):
                    text = ' '.join(
                        item.get('text', '')
                        for item in content
                        if isinstance(item, dict) and item.get('type') == 'text'
                    )
                break
        except json.JSONDecodeError:
            continue

    if not text:
        sys.exit(0)

    # パターン検出
    found = []
    for p in TENTATIVE_PATTERNS:
        match = re.search(p, text)
        if match:
            found.append(match.group(0))

    if found:
        output = {
            "decision": "block",
            "reason": f"不確実な表現を検出しました: {', '.join(found)}\n\nこれらの表現は曖昧な判断を示唆しています。なぜその判断をしたのか、確実な根拠に基づいて再考し、より明確な表現で回答してください。"
        }
        print(json.dumps(output, ensure_ascii=False))

    sys.exit(0)

if __name__ == '__main__':
    main()
