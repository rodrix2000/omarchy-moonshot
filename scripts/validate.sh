#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

omarchy_root="${OMARCHY_PATH:-/usr/share/omarchy}"

echo "==> Running omarchy plugin validate..."
omarchy plugin validate "$ROOT"

echo "==> Running package check..."
"$ROOT/scripts/package-check.sh"

echo "==> Running safety check..."
"$ROOT/scripts/safety-check.sh"

echo "==> Running QML check..."
"$ROOT/scripts/qml-check.sh"

echo "==> Running Python tests..."
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v

echo "==> Running QML runtime smoke tests with Quickshell..."
"$ROOT/scripts/qml-runtime-check.sh"

echo "==> All validation checks passed!"
