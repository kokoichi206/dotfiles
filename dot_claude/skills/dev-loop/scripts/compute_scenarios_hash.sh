#!/usr/bin/env bash
#
# Compute stable hash of scenarios.md.
# Used by dev-plan (record), dev-generate (self-verify), dev-evaluate (verify).
#
# Usage: compute_scenarios_hash.sh <scenarios_md_path>
#
# Cross-platform (macOS / Linux) via shasum -a 256.
set -euo pipefail

FILE="${1:?scenarios_md_path is required}"

if [ ! -f "$FILE" ]; then
  echo "ERROR: file not found: $FILE" >&2
  exit 1
fi

if ! command -v shasum &>/dev/null; then
  echo "ERROR: shasum not found (required on both macOS and Linux)" >&2
  exit 1
fi

shasum -a 256 "$FILE" | awk '{print $1}'
