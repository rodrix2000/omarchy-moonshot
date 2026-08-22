#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Ensure no sudo/pkexec/tracking in executable source code
forbidden_patterns='(sudo |pkexec |systemctl |google-analytics|telemetry_client)'

if grep -rnE "$forbidden_patterns" \
  --include='*.py' \
  --include='*.qml' \
  --include='*.js' \
  --include='*.sh' \
  --exclude-dir='vendor' \
  --exclude='safety-check.sh' \
  .; then
  echo "error: forbidden privileged or tracking strings found in source code" >&2
  exit 1
fi

echo "safety-check: OK"
