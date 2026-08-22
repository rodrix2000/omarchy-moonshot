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

qml_files=()
while IFS= read -r -d '' file; do
  qml_files+=("$file")
done < <(find . -maxdepth 2 -type f -name '*.qml' -not -path './vendor/*' -print0)

qml_imports=(-I "$omarchy_root/shell")
if [[ -f "$omarchy_root/shell/Ui/qmldir" && -f "$omarchy_root/shell/Commons/qmldir" ]]; then
  qml_imports=(
    -i "$omarchy_root/shell/Ui/qmldir"
    -i "$omarchy_root/shell/Commons/qmldir"
  )
fi

if [[ ${#qml_files[@]} -gt 0 ]]; then
  "$qml_lint" -W 0 "${qml_imports[@]}" "${qml_files[@]}"
fi

echo "qml-check: OK"
