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

qml_files=(
  MoonDisk.qml
  MoonshotIcon.qml
  MoonshotButton.qml
  MoonshotContent.qml
  LunarCalendar.qml
  LunarTimeline.qml
  EclipseTracking.qml
  AstronomyClient.qml
  MoonshotModel.qml
  LocationEditor.qml
  BarWidget.qml
  Panel.qml
)

qml_imports=()
if [[ -f "$omarchy_root/shell/Ui/qmldir" && -f "$omarchy_root/shell/Commons/qmldir" ]]; then
  # Omarchy's source tree uses logical module names (qs.Ui/qs.Commons)
  # without mirroring that URI as qs/Ui on disk. Feed the qmldir manifests
  # directly so qmllint resolves the same source modules Quickshell does.
  qml_imports=(
    -i "$omarchy_root/shell/Commons/qmldir"
    -i "$omarchy_root/shell/Ui/qmldir"
  )
fi

# Omarchy ships source qmldir manifests without generated qmltypes, so
# singleton members and Loader targets appear as generic QObject properties
# to qmllint. The hard Quickshell runtime gate covers those dynamic members.
"$qml_lint" -W 0 \
  --signal-handler-parameters disable \
  --missing-property disable \
  --unqualified disable \
  --unused-imports warning \
  "${qml_imports[@]}" "${qml_files[@]}"

echo "qml-check: OK"
