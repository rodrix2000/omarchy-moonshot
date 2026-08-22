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

if find . -type d -name '__pycache__' -print -quit | grep -q .; then
  echo "error: Python bytecode cache found in repository" >&2
  find . -type d -name '__pycache__' -print >&2
  exit 1
fi

# Check manifest exists and validates
if ! omarchy plugin validate .; then
  echo "error: omarchy plugin validate failed" >&2
  exit 1
fi

# The runtime texture must remain a bounded, true-alpha PNG. This prevents a
# generated checkerboard or an accidentally huge source image from shipping.
python3 - <<'PY'
from pathlib import Path
import struct

path = Path("assets/moon-surface-v2.png")
if not path.is_file():
    raise SystemExit("error: required lunar texture is missing")

data = path.read_bytes()
if data[:8] != b"\x89PNG\r\n\x1a\n" or len(data) < 33:
    raise SystemExit("error: lunar texture is not a valid PNG")
width, height, bit_depth, color_type = struct.unpack(">IIBB", data[16:26])
if width != height or not (256 <= width <= 1024):
    raise SystemExit(f"error: lunar texture must be square and 256–1024 px, got {width}x{height}")
if bit_depth != 8 or color_type not in (4, 6):
    raise SystemExit("error: lunar texture must be an 8-bit PNG with an alpha channel")
if len(data) > 1_500_000:
    raise SystemExit(f"error: lunar texture exceeds 1.5 MB ({len(data)} bytes)")
PY

echo "package-check: OK"
