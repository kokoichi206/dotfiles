#!/usr/bin/env python3
"""Claude Code と Codex の利用枠を取得して ~/.cache/wezterm/agent-usage.json に書く。

wezterm の update-status から呼ばれるため、以下を守る:
- 常にバックグラウンドで起動される。呼び出し側は完了を待たない。
- 書き込みは tmp + rename で原子的に行う。半端な JSON を読ませない。
- 同時起動はロックで 1 本に畳む。複数ウィンドウから呼ばれても叩く回数は増えない。

呼び出し間隔の制御は呼び出し側 (agent-usage.lua) の責務で、ここでは行わない。

wezterm は macOS 同梱の /usr/bin/python3 (3.9) で起動するため、3.9 で動く範囲で書く。
"""

import errno
import fcntl
import getpass
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import unicodedata
import urllib.error
import urllib.request

CLAUDE_URL = "https://api.anthropic.com/api/oauth/usage"
CODEX_URL = "https://chatgpt.com/backend-api/wham/usage"
GROK_BASE = (os.environ.get("GROK_CLI_CHAT_PROXY_BASE_URL")
             or "https://cli-chat-proxy.grok.com/v1").rstrip("/")
TIMEOUT_SECONDS = 10

# 429 で retry-after が無いときに空ける時間。
DEFAULT_BACKOFF_SECONDS = 600

CACHE_DIR = os.path.expanduser("~/.cache/wezterm")
CACHE_PATH = os.path.join(CACHE_DIR, "agent-usage.json")
LOCK_PATH = os.path.join(CACHE_DIR, "agent-usage.lock")


class Throttled(Exception):
    """HTTP 429。retry_until までは再試行しない。"""

    def __init__(self, retry_until):
        super().__init__("rate limited")
        self.retry_until = retry_until


def fetch_json(url, headers):
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as res:
            return json.load(res)
    except urllib.error.HTTPError as e:
        if e.code == 429:
            raise Throttled(time.time() + parse_retry_after(e.headers.get("retry-after")))
        raise RuntimeError("HTTP {} {}".format(e.code, error_reason(e)).strip())


def error_reason(http_error):
    """本文に入っている理由を短く取り出す。バーは 1 行なので 40 文字で切る。"""
    try:
        body = json.loads(http_error.read().decode("utf-8", "replace"))
    except Exception:  # noqa: BLE001 - 本文が無い・JSON でないことは珍しくない
        return ""
    detail = body.get("error") if isinstance(body, dict) else None
    if isinstance(detail, dict):
        return str(detail.get("type") or detail.get("message") or "")[:40]
    return str(body.get("detail") or body.get("message") or "")[:40] if isinstance(body, dict) else ""


def parse_retry_after(value):
    try:
        return max(1.0, float(value))
    except (TypeError, ValueError):
        return DEFAULT_BACKOFF_SECONDS


def epoch(value):
    """resets_at を epoch 秒に正規化する。API は ISO 8601 文字列と epoch 秒の両方を返す。"""
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value) / 1000.0 if value > 1e10 else float(value)
    text = str(value).strip()
    if not text:
        return None
    try:
        number = float(text)
        return number / 1000.0 if number > 1e10 else number
    except ValueError:
        pass
    # "2026-09-24T20:00:00.633566+00:00" 形式。3.9 の fromisoformat は Z を扱えない。
    from datetime import datetime

    try:
        return datetime.fromisoformat(text.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


def limit(percent, resets_at, window_minutes, label=None):
    """window_minutes は描画側がゲージを付ける枠 (最短の窓) を選ぶのに使う。"""
    if percent is None:
        return None
    entry = {
        "percent": max(0, min(100, int(round(percent)))),
        "resets_at": epoch(resets_at),
        "window_minutes": window_minutes,
    }
    if label:
        entry["label"] = label
    return entry


def claude_limits(body):
    """five_hour / seven_day と、モデル単位の weekly_scoped を取り出す。

    weekly_scoped は limits[] にしか出ないため、そちらを正本にする。
    """
    def percent_of(window):
        if not isinstance(window, dict):
            return None, None
        value = window.get("utilization")
        if value is None:
            value = window.get("used_percentage")
        return value, window.get("resets_at")

    session_percent, session_resets = percent_of(body.get("five_hour"))
    weekly_percent, weekly_resets = percent_of(body.get("seven_day"))

    scoped = None
    for entry in body.get("limits") or []:
        if not isinstance(entry, dict) or entry.get("kind") != "weekly_scoped":
            continue
        name = ((entry.get("scope") or {}).get("model") or {}).get("display_name")
        if name and entry.get("percent") is not None:
            scoped = limit(entry["percent"], entry.get("resets_at"), 10080, name.strip())
            break

    return {
        "ok": True,
        "session": limit(session_percent, session_resets, 300),
        "weekly": limit(weekly_percent, weekly_resets, 10080),
        "scoped": scoped,
    }


def codex_limits(body):
    """primary / secondary を window 長で session と weekly に振り分ける。

    どちらがどちらかは固定されないため、300 分なら session、10080 分なら weekly と見る。
    """
    def window(raw):
        if not isinstance(raw, dict) or raw.get("used_percent") is None:
            return None, None
        seconds = raw.get("limit_window_seconds")
        minutes = seconds / 60.0 if isinstance(seconds, (int, float)) and seconds > 0 else None
        return limit(raw["used_percent"], raw.get("reset_at"), minutes), minutes

    rate = body.get("rate_limit") or {}
    session = None
    weekly = None
    for raw in (rate.get("primary_window"), rate.get("secondary_window")):
        entry, minutes = window(raw)
        if entry is None:
            continue
        if minutes is not None and abs(minutes - 300) <= 1 and session is None:
            session = entry
        elif minutes is not None and abs(minutes - 10080) <= 1 and weekly is None:
            weekly = entry
        elif weekly is None:
            weekly = entry

    return {"ok": True, "plan": body.get("plan_type"), "session": session, "weekly": weekly}


def claude_config_dir():
    scoped = os.environ.get("CLAUDE_SECURESTORAGE_CONFIG_DIR")
    if scoped:
        return scoped
    return os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude")


def keychain_service():
    """Claude Code が keychain 項目に使う service 名を同じ規則で組み立てる。

    設定ディレクトリを環境変数で移している場合だけ、その sha256 の先頭 8 桁が後ろに付く。
    """
    scoped = os.environ.get("CLAUDE_SECURESTORAGE_CONFIG_DIR")
    if scoped is not None:
        unscoped = not scoped
    else:
        unscoped = not os.environ.get("CLAUDE_CONFIG_DIR")
    if unscoped:
        return "Claude Code-credentials"
    digest = hashlib.sha256(
        unicodedata.normalize("NFC", claude_config_dir()).encode("utf-8")
    ).hexdigest()[:8]
    return "Claude Code-credentials-{}".format(digest)


def keychain_account():
    name = os.environ.get("USER") or getpass.getuser()
    return name if re.match(r"^[a-zA-Z0-9._-]+$", name) else "claude-code-user"


def claude_credentials():
    """keychain を正本とし、平文ファイルは fallback。Claude Code 本体と同じ順序。

    Claude Code は keychain への書き込みに成功すると平文ファイルを消すため、
    ファイルだけが残っている環境ではそちらが期限切れになっている。
    """
    try:
        result = subprocess.run(
            ["security", "find-generic-password",
             "-a", keychain_account(), "-w", "-s", keychain_service()],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=10,
        )
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout.decode("utf-8").strip())
    except (OSError, ValueError, subprocess.SubprocessError):
        pass
    with open(os.path.join(claude_config_dir(), ".credentials.json")) as f:
        return json.load(f)


def claude():
    token = (claude_credentials().get("claudeAiOauth") or {}).get("accessToken")
    if not token:
        raise RuntimeError("no claude token")
    return claude_limits(fetch_json(CLAUDE_URL, {
        "Authorization": "Bearer {}".format(token),
        "anthropic-beta": "oauth-2025-04-20",
        "User-Agent": "claude-code/2.1.0",
    }))


def codex():
    home = os.environ.get("CODEX_HOME") or os.path.expanduser("~/.codex")
    with open(os.path.join(home, "auth.json")) as f:
        tokens = json.load(f).get("tokens") or {}
    if not tokens.get("access_token"):
        raise RuntimeError("no codex token")
    headers = {
        "Authorization": "Bearer {}".format(tokens["access_token"]),
        "User-Agent": "codex-cli",
        "OpenAI-Beta": "codex-1",
        "originator": "Codex Desktop",
    }
    if tokens.get("account_id"):
        headers["ChatGPT-Account-Id"] = tokens["account_id"]
    return codex_limits(fetch_json(CODEX_URL, headers))


def describe(error):
    """バーは 1 行なので、原因が分かる最短の語にする。"""
    if isinstance(error, RuntimeError):
        return str(error)
    if isinstance(error, urllib.error.URLError):
        return "network"
    if isinstance(error, (FileNotFoundError, PermissionError)):
        return "not signed in"
    if isinstance(error, ValueError):
        return "bad credentials"
    return type(error).__name__


def grok_limits(body):
    """x.ai は現在の課金期間を 1 つだけ返す。期間の長さは start/end の差から出す。

    週次と月次のどちらが返るかは契約によるため、種別を決め打ちしない。
    """
    config = body.get("config") or {}
    period = config.get("currentPeriod") or {}
    start = epoch(period.get("start") or config.get("billingPeriodStart"))
    end = epoch(period.get("end") or config.get("billingPeriodEnd"))
    minutes = int(round((end - start) / 60.0)) if start and end and end > start else None
    return {"ok": True, "period": limit(config.get("creditUsagePercent"), end, minutes)}


def grok():
    with open(os.path.expanduser("~/.grok/auth.json")) as f:
        raw = json.load(f)
    # 発行元ごとにキーが分かれる。トークンを持つ最初のものを使う。
    cred = next((v for v in raw.values() if isinstance(v, dict) and v.get("key")), None)
    if not cred:
        raise RuntimeError("no grok token")
    headers = {
        "Authorization": "Bearer {}".format(cred["key"]),
        "X-XAI-Token-Auth": "xai-grok-cli",
        "Accept": "application/json",
    }
    if cred.get("user_id"):
        headers["x-userid"] = cred["user_id"]
    return grok_limits(fetch_json(GROK_BASE + "/billing?format=credits", headers))


def collect():
    """どれかが落ちても、他の結果は残す。"""
    result = {"fetched_at": time.time(), "retry_until": 0}
    for name, fn in (("claude", claude), ("codex", codex), ("grok", grok)):
        try:
            result[name] = fn()
        except Throttled as e:
            result[name] = {"ok": False, "error": "rate limited"}
            result["retry_until"] = max(result["retry_until"], e.retry_until)
        except Exception as e:  # noqa: BLE001 - 取得失敗の理由をそのままバーに出す
            result[name] = {"ok": False, "error": describe(e)}
    return result


def write_atomic(payload):
    tmp = CACHE_PATH + ".tmp.{}".format(os.getpid())
    with open(tmp, "w") as f:
        json.dump(payload, f)
    os.replace(tmp, CACHE_PATH)


def main():
    os.makedirs(CACHE_DIR, exist_ok=True)
    lock = open(LOCK_PATH, "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError as e:
        if e.errno in (errno.EACCES, errno.EAGAIN):
            return 0
        raise
    write_atomic(collect())
    return 0


if __name__ == "__main__":
    sys.exit(main())
