#!/bin/bash
# Chrome を CDP 付きで起動するスクリプト
# Usage: ./start-chrome-cdp.sh [profile-name] [port]
#
# Examples:
#   ./start-chrome-cdp.sh "Profile 1" 9222
#   ./start-chrome-cdp.sh "Default" 9223

PROFILE="${1:-Profile 1}"
PORT="${2:-9222}"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CHROME_DATA="$HOME/Library/Application Support/Google/Chrome"
CDP_DATA="/tmp/chrome-cdp-data-${PORT}"

# 既存の CDP Chrome を停止
if lsof -i ":${PORT}" &>/dev/null; then
  echo "Port ${PORT} is already in use. Kill existing process? (y/n)"
  read -r answer
  if [ "$answer" = "y" ]; then
    lsof -ti ":${PORT}" | xargs kill -9 2>/dev/null
    sleep 2
  else
    echo "Aborting."
    exit 1
  fi
fi

# プロファイルをコピー（ログイン済みセッションを維持するため）
echo "Copying Chrome profile '${PROFILE}'..."
rm -rf "$CDP_DATA" 2>/dev/null
mkdir -p "$CDP_DATA"
cp -R "${CHROME_DATA}/${PROFILE}" "${CDP_DATA}/Default" 2>/dev/null
cp "${CHROME_DATA}/Local State" "${CDP_DATA}/" 2>/dev/null
echo "Profile copied to ${CDP_DATA} ($(du -sh "$CDP_DATA" | cut -f1))"

# Chrome を CDP 付きで起動
echo "Starting Chrome with CDP on port ${PORT}..."
"$CHROME" \
  --remote-debugging-port="$PORT" \
  --user-data-dir="$CDP_DATA" \
  --profile-directory="Default" \
  --no-first-run \
  &>/dev/null &

CHROME_PID=$!
echo "Chrome PID: ${CHROME_PID}"

# CDP 接続を待機
echo "Waiting for CDP..."
for i in $(seq 1 15); do
  if curl -s "http://localhost:${PORT}/json/version" &>/dev/null; then
    BROWSER=$(curl -s "http://localhost:${PORT}/json/version" | python3 -c "import sys,json; print(json.load(sys.stdin).get('Browser',''))" 2>/dev/null)
    echo "✓ CDP ready: ${BROWSER} on port ${PORT}"
    echo ""
    echo "Connect with: npx agent-browser connect ${PORT}"
    exit 0
  fi
  sleep 1
done

echo "✗ CDP connection timeout. Check Chrome logs."
exit 1
