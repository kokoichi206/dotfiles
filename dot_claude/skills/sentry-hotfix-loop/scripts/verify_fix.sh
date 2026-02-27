#!/usr/bin/env bash
set -euo pipefail

CHECKS_FILE="${1:?checks file is required}"
REPORT_FILE="${2:-./tmp/fix-verify-report.md}"

if [ ! -f "${CHECKS_FILE}" ]; then
  echo "checks file not found: ${CHECKS_FILE}" >&2
  exit 1
fi

mkdir -p "$(dirname "${REPORT_FILE}")"

{
  echo "# Fix Verification Report"
  echo
  echo "generated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
} > "${REPORT_FILE}"

while IFS= read -r cmd; do
  [ -z "${cmd}" ] && continue
  [ "${cmd#\#}" != "${cmd}" ] && continue

  echo "## ${cmd}" >> "${REPORT_FILE}"
  if bash -lc "${cmd}" >> "${REPORT_FILE}" 2>&1; then
    echo "- result: PASS" >> "${REPORT_FILE}"
  else
    echo "- result: FAIL" >> "${REPORT_FILE}"
    echo "Verification failed at command: ${cmd}" >&2
    exit 1
  fi
  echo >> "${REPORT_FILE}"
done < "${CHECKS_FILE}"

echo "Wrote verification report to ${REPORT_FILE}"
