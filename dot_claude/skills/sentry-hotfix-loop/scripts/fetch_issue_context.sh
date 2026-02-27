#!/usr/bin/env bash
# sentry-cli は releases/sourcemaps 管理が主で、issue 詳細・events・tags の
# 取得コマンドを持たない。そのため API を直接叩く。
# 認証は ~/.sentryclirc から自動で読み、org slug は sentry-cli から取得する。
set -euo pipefail

ISSUE_SHORT_ID="${1:?usage: fetch_issue_context.sh <issue-short-id|--list [project-slug]> [output-dir]}"

# --list の場合は $2 を project-slug として扱う
if [ "${ISSUE_SHORT_ID}" = "--list" ]; then
  LIST_PROJECT="${2:-}"
else
  OUT_DIR="${2:-./tmp/sentry-issue-context}"
fi

# --- auth token: 環境変数 > ~/.sentryclirc ---
if [ -z "${SENTRY_AUTH_TOKEN:-}" ]; then
  SENTRYCLIRC="${HOME}/.sentryclirc"
  if [ -f "${SENTRYCLIRC}" ]; then
    SENTRY_AUTH_TOKEN="$(grep -E '^token=' "${SENTRYCLIRC}" | head -1 | cut -d= -f2-)"
  fi
fi
if [ -z "${SENTRY_AUTH_TOKEN:-}" ]; then
  echo "SENTRY_AUTH_TOKEN not found. Set env var or configure ~/.sentryclirc" >&2
  exit 1
fi

# --- org slug: 環境変数 > sentry-cli ---
if [ -z "${SENTRY_ORG_SLUG:-}" ]; then
  if command -v sentry-cli &>/dev/null; then
    ORG_LIST="$(sentry-cli organizations list --raw 2>/dev/null || true)"
    ORG_COUNT="$(echo "${ORG_LIST}" | grep -c . || true)"
    if [ "${ORG_COUNT}" -gt 1 ]; then
      echo "Warning: ${ORG_COUNT} orgs found. Using first one. Set SENTRY_ORG_SLUG to specify." >&2
    fi
    SENTRY_ORG_SLUG="$(echo "${ORG_LIST}" | head -1)"
  fi
fi
if [ -z "${SENTRY_ORG_SLUG:-}" ]; then
  echo "SENTRY_ORG_SLUG not found. Set env var or install sentry-cli" >&2
  exit 1
fi

SENTRY_BASE_URL="${SENTRY_BASE_URL:-https://sentry.io}"
CURL="${CURL:-curl}"

# --- --list: 未解決 issue 一覧 ---
if [ "${ISSUE_SHORT_ID}" = "--list" ]; then
  LIST_URL="${SENTRY_BASE_URL}/api/0/organizations/${SENTRY_ORG_SLUG}/issues/?query=is:unresolved&limit=25&sort=date"
  if [ -n "${LIST_PROJECT}" ]; then
    LIST_URL="${SENTRY_BASE_URL}/api/0/projects/${SENTRY_ORG_SLUG}/${LIST_PROJECT}/issues/?query=is:unresolved&limit=25&sort=date"
  fi
  "${CURL}" -sS -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" "${LIST_URL}" \
    | jq -r '.[] | "\(.shortId)\t\(.level)\t\(.count)x\t\(.title)"'
  exit 0
fi

mkdir -p "${OUT_DIR}"

SEARCH_URL="${SENTRY_BASE_URL}/api/0/organizations/${SENTRY_ORG_SLUG}/issues/?query=shortId:${ISSUE_SHORT_ID}"

"${CURL}" -sS \
  -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
  "${SEARCH_URL}" > "${OUT_DIR}/issues_search.json"

GROUP_ID="$(jq -r '.[0].id // empty' "${OUT_DIR}/issues_search.json")"

if [ -z "${GROUP_ID}" ]; then
  echo "Issue not found: ${ISSUE_SHORT_ID}" >&2
  exit 1
fi

"${CURL}" -sS \
  -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
  "${SENTRY_BASE_URL}/api/0/issues/${GROUP_ID}/" > "${OUT_DIR}/issue.json"

"${CURL}" -sS \
  -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
  "${SENTRY_BASE_URL}/api/0/issues/${GROUP_ID}/events/?limit=20" > "${OUT_DIR}/events.json"

"${CURL}" -sS \
  -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
  "${SENTRY_BASE_URL}/api/0/issues/${GROUP_ID}/tags/" > "${OUT_DIR}/tags.json"

echo "Wrote issue context to ${OUT_DIR}"
