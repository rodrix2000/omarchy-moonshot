#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
omarchy_root="${OMARCHY_PATH:-/usr/share/omarchy}"
quickshell_bin=$(command -v qs || command -v quickshell || true)

if [[ -z "$quickshell_bin" ]]; then
  echo "qml-runtime-check: quickshell was not found" >&2
  exit 1
fi

stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/omarchy-moonshot-qml.XXXXXX")
cleanup() {
  rm -rf "$stage_dir"
}
trap cleanup EXIT

mkdir -p "$stage_dir/repo" "$stage_dir/runtime" "$stage_dir/state" \
  "$stage_dir/cache" "$stage_dir/config" "$stage_dir/home"
chmod 700 "$stage_dir/runtime" "$stage_dir/state"
cp -a "$root_dir/." "$stage_dir/repo/"
cp -a "$omarchy_root/shell/Commons" "$stage_dir/repo/Commons"
cp -a "$omarchy_root/shell/Ui" "$stage_dir/repo/Ui"

run_scene() {
  local scene=$1
  local marker=$2
  local log_file="$stage_dir/$(basename "$scene").log"
  local staged_scene="$stage_dir/repo/shell.qml"

  # Keep the entrypoint at the staged repo root. Quickshell deliberately
  # rejects relative imports that escape its config folder.
  cp "$stage_dir/repo/$scene" "$staged_scene"
  sed -i -e 's#import "../../"#import "."#g' "$staged_scene"

  if ! timeout 12s env -u DISPLAY -u WAYLAND_DISPLAY \
    XDG_CONFIG_HOME="$stage_dir/config" \
    XDG_STATE_HOME="$stage_dir/state" \
    XDG_CACHE_HOME="$stage_dir/cache" \
    XDG_RUNTIME_DIR="$stage_dir/runtime" \
    HOME="$stage_dir/home" \
    QT_QPA_PLATFORM=minimal \
    QT_QUICK_BACKEND=software \
    QT_QPA_PLATFORMTHEME= \
    "$quickshell_bin" --no-color -p "$staged_scene" >"$log_file" 2>&1; then
    sed -n '1,220p' "$log_file" >&2
    echo "qml-runtime-check: $scene failed" >&2
    exit 1
  fi

  if ! grep -Fq "$marker" "$log_file"; then
    sed -n '1,220p' "$log_file" >&2
    echo "qml-runtime-check: $scene did not reach its success marker" >&2
    exit 1
  fi
}

run_scene tests/qml/RenderSmoke.qml "RenderSmoke: Canvas rendered successfully"
run_scene tests/qml/LifecycleSmoke.qml "LifecycleSmoke: MoonshotModel received snapshot OK"
run_scene tests/qml/StateSmoke.qml "StateSmoke: travel presets persisted and switched OK"
run_scene tests/qml/LocationEditorSmoke.qml "LocationEditorSmoke: saved places and guarded reset OK"

python3 - "$stage_dir/state/moonshot/settings-v1.json" <<'PY'
from pathlib import Path
import json
import stat
import sys

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit("qml-runtime-check: state smoke did not create settings-v1.json")
doc = json.loads(path.read_text(encoding="utf-8"))
if doc.get("version") != 1 or doc.get("locationConfigured") is not True:
    raise SystemExit("qml-runtime-check: persisted state has an invalid schema")
if doc.get("timeZone") != "America/Chicago" or doc.get("locationLabel") != "Runtime Test":
    raise SystemExit("qml-runtime-check: persisted state does not match validated input")
saved = doc.get("savedLocations")
if not isinstance(saved, list) or len(saved) != 2:
    raise SystemExit("qml-runtime-check: saved-place list has an invalid shape")
if [place.get("locationLabel") for place in saved] != ["Runtime Test", "Travel Test"]:
    raise SystemExit("qml-runtime-check: saved-place order was not persisted")
if stat.S_IMODE(path.stat().st_mode) != 0o600:
    raise SystemExit("qml-runtime-check: persisted state is not mode 0600")
if stat.S_IMODE(path.parent.stat().st_mode) != 0o700:
    raise SystemExit("qml-runtime-check: state directory is not mode 0700")
PY

echo "qml-runtime-check: OK"
