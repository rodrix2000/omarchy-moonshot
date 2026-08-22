#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/validate.sh"

# Check manifest version matches changelog
manifest_ver="$(python3 -c 'import json; print(json.load(open("manifest.json"))["version"])')"
if ! grep -q "## \[$manifest_ver\]" CHANGELOG.md; then
  echo "error: version $manifest_ver not found in CHANGELOG.md" >&2
  exit 1
fi

echo "release-check: OK for version $manifest_ver"
