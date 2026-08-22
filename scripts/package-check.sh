#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Check for forbidden symlinks
if [[ $(find . -type l | wc -l) -gt 0 ]]; then
  echo "error: symlinks found in repository" >&2
  find . -type l >&2
  exit 1
fi

# Check for forbidden hidden temporary/cache directories
for forbidden in .venv venv build dist htmlcov .pytest_cache .mypy_cache; do
  if [[ -d "$forbidden" ]]; then
    echo "error: forbidden directory present: $forbidden" >&2
    exit 1
  fi
done

# Check manifest exists and validates
if ! omarchy plugin validate .; then
  echo "error: omarchy plugin validate failed" >&2
  exit 1
fi

echo "package-check: OK"
