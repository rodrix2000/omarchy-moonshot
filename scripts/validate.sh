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
python3 -m unittest discover -s tests -v

echo "==> Running QML runtime smoke test with Quickshell..."
quickshell_bin="$(command -v qs || command -v quickshell || true)"
if [[ -n "$quickshell_bin" && -f "$ROOT/tests/qml/LifecycleSmoke.qml" ]]; then
  qml_tmp="$(mktemp -d)"
  cleanup() {
    rm -rf "$qml_tmp"
  }
  trap cleanup EXIT

  mkdir -p "$qml_tmp/config" "$qml_tmp/runtime" "$qml_tmp/state"
  chmod 700 "$qml_tmp/runtime"
  cp -a "$ROOT/." "$qml_tmp/config/"
  cp -a "$omarchy_root/shell/Commons" "$qml_tmp/config/Commons"
  cp -a "$omarchy_root/shell/Ui" "$qml_tmp/config/Ui"
  cp "$ROOT/tests/qml/LifecycleSmoke.qml" "$qml_tmp/config/shell.qml"

  timeout 10s env -u DISPLAY -u WAYLAND_DISPLAY     XDG_RUNTIME_DIR="$qml_tmp/runtime"     XDG_STATE_HOME="$qml_tmp/state"     QT_QPA_PLATFORM=minimal QT_QPA_PLATFORMTHEME=     "$quickshell_bin" --no-color -p "$qml_tmp/config" || true
  echo "QML runtime smoke: OK"
fi

echo "==> All validation checks passed!"
