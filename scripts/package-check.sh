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

# Perform portable manifest/package checks here so this script can run on a
# stock CI host. The release gate separately runs `omarchy plugin validate` on
# the supported Omarchy machine.
python3 - <<'PY'
import json
from pathlib import Path

root = Path.cwd()
manifest_path = root / "manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
required = {"schemaVersion", "id", "name", "version", "license", "kinds", "entryPoints"}
missing = sorted(required - manifest.keys())
assert not missing, f"manifest missing required fields: {missing}"
assert manifest["schemaVersion"] == 1
assert manifest["id"] == "io.github.rodrix2000.moonshot"
assert manifest["license"] == "MIT"
assert manifest["kinds"] == ["bar-widget"]
assert manifest["entryPoints"].get("barWidget") == "BarWidget.qml"
assert set(manifest["entryPoints"]) == {"barWidget"}

panel_source = (root / "Panel.qml").read_text(encoding="utf-8")
bar_source = (root / "BarWidget.qml").read_text(encoding="utf-8")
client_source = (root / "AstronomyClient.qml").read_text(encoding="utf-8")
helper_source = (root / "scripts/moonshot_ephemeris.py").read_text(encoding="utf-8")
assert "Ui.KeyboardPanel" in panel_source
assert "FloatingWindow" not in panel_source
assert 'source: Qt.resolvedUrl("Panel.qml")' in bar_source
assert '["python3", "-B", root.helperPath' in client_source
assert "sys.dont_write_bytecode = True" in helper_source

for entry in manifest["entryPoints"].values():
    path = Path(entry)
    assert not path.is_absolute() and ".." not in path.parts, entry
    assert (root / path).is_file(), entry

for required_file in (
    "README.md",
    "LICENSE",
    "SECURITY.md",
    "THIRD_PARTY_NOTICES.md",
    "preview.png",
    "docs/screenshots/tonight.png",
    "docs/screenshots/calendar.png",
    "docs/screenshots/cycle.png",
    "docs/screenshots/eclipses.png",
):
    assert (root / required_file).is_file(), required_file
PY

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
