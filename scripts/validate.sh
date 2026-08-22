#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Running omarchy plugin validate..."
omarchy plugin validate "$ROOT"

echo "==> Running package check..."
"$ROOT/scripts/package-check.sh"

echo "==> Running safety check..."
"$ROOT/scripts/safety-check.sh"

echo "==> Running QML check..."
"$ROOT/scripts/qml-check.sh"

echo "==> Running Python tests..."
python3 -m unittest discover -s tests -v

echo "==> All validation checks passed!"
