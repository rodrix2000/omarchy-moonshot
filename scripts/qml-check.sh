#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

omarchy_root="${OMARCHY_PATH:-/usr/share/omarchy}"
qml_lint="${QMLLINT:-}"
if [[ -z "$qml_lint" ]]; then
  qml_lint="$(command -v qmllint || true)"
fi
if [[ -z "$qml_lint" && -x /usr/lib/qt6/bin/qmllint ]]; then
  qml_lint="/usr/lib/qt6/bin/qmllint"
fi
if [[ -z "$qml_lint" ]]; then
  echo "warning: qmllint was not found, skipping qmllint check" >&2
  exit 0
fi

qml_files=(MoonDisk.qml AstronomyClient.qml MoonshotModel.qml LocationEditor.qml BarWidget.qml Panel.qml)

qml_imports=()
if [[ -f "$omarchy_root/shell/Ui/qmldir" && -f "$omarchy_root/shell/Commons/qmldir" ]]; then
  qml_imports=(
    -i "$omarchy_root/shell/Ui/qmldir"
    -i "$omarchy_root/shell/Commons/qmldir"
  )
fi

"$qml_lint" -W 0 \
  --signal-handler-parameters info \
  --missing-property info \
  --unqualified info \
  --unused-imports info \
  "${qml_imports[@]}" "${qml_files[@]}"

echo "qml-check: OK"
