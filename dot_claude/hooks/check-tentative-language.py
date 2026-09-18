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


def extract_assistant_text(entry):
    """transcript の 1 エントリからアシスタントのテキストを取り出す。

    Claude Code の transcript は {"type": "assistant", "message": {"role": ..., "content": [...]}}
    の入れ子形式。旧フラット形式 {"role": "assistant", "content": ...} も受ける。
    """
    message = entry.get('message') if entry.get('type') == 'assistant' else entry
    if not isinstance(message, dict) or message.get('role') != 'assistant':
        return None

    content = message.get('content', '')
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return ' '.join(
            item.get('text', '')
            for item in content
            if isinstance(item, dict) and item.get('type') == 'text'
        )
    return None


def main():
    try:
        hook_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    # block 後の再実行では再ブロックしない（無限ループ防止）
    if hook_input.get('stop_hook_active'):
        sys.exit(0)

    transcript_path = hook_input.get('transcript_path', '')

    if not transcript_path or not Path(transcript_path).exists():
        sys.exit(0)

    try:
        with open(transcript_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception:
        sys.exit(0)

    text = ""
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        extracted = extract_assistant_text(entry)
        if extracted is not None:
            text = extracted
            break

    if not text:
        sys.exit(0)

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
