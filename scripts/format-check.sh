#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root_dir"

mapfile -t text_files < <(rg --files \
  -g '*.qml' -g '*.js' -g '*.py' -g '*.sh' -g '*.md' -g '*.json' -g 'Makefile' \
  -g '!vendor/**')

if rg -n '[[:blank:]]+$' "${text_files[@]}"; then
  echo "format-check: trailing whitespace found" >&2
  exit 1
fi

for file in "${text_files[@]}"; do
  if [[ -s "$file" && $(tail -c 1 "$file" | wc -l) -eq 0 ]]; then
    echo "format-check: missing final newline: $file" >&2
    exit 1
  fi
done

echo "format-check: OK"
