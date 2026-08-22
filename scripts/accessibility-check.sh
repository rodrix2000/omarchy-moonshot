#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root_dir"

required_patterns=(
  'Accessible.name: root.accessibleDescription'
  'Accessible.name: "Moonshot lunar details"'
  'Accessible.name: "Moonshot location settings"'
  'focusable: true'
  'Keys.onEscapePressed'
  'text === "L"'
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -R -Fq "$pattern" --include='*.qml' .; then
    echo "accessibility-check: missing required pattern: $pattern" >&2
    exit 1
  fi
done

if grep -R -nE '🌕|🌑|📍|⚠️' --include='*.qml' .; then
  echo "accessibility-check: emoji controls are not allowed" >&2
  exit 1
fi

echo "accessibility-check: static keyboard, naming, focus, and non-emoji checks OK"
