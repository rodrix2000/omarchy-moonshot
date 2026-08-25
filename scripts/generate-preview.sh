#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
capture_dir="$repo_dir/docs/screenshots"
stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/omarchy-moonshot-preview.XXXXXX")
trap 'rm -rf "$stage_dir"' EXIT

for name in tonight calendar cycle eclipses; do
  if [[ ! -f "$capture_dir/$name.png" ]]; then
    echo "generate-preview: missing live capture: docs/screenshots/$name.png" >&2
    exit 1
  fi
done

if ! command -v magick >/dev/null 2>&1; then
  echo "generate-preview: ImageMagick 'magick' is required" >&2
  exit 1
fi

read -r tonight_w tonight_h < <(magick identify -format '%w %h\n' "$capture_dir/tonight.png")
read -r calendar_w calendar_h < <(magick identify -format '%w %h\n' "$capture_dir/calendar.png")
read -r cycle_w cycle_h < <(magick identify -format '%w %h\n' "$capture_dir/cycle.png")
read -r eclipses_w eclipses_h < <(magick identify -format '%w %h\n' "$capture_dir/eclipses.png")

if (( tonight_w != calendar_w || tonight_w != cycle_w || tonight_w != eclipses_w )); then
  echo "generate-preview: all live popup captures must have the same width" >&2
  exit 1
fi

top_h=$((tonight_h > calendar_h ? tonight_h : calendar_h))
bottom_h=$((cycle_h > eclipses_h ? cycle_h : eclipses_h))
gap=18
border=18
background='#070b10'

magick "$capture_dir/tonight.png" -gravity north -background "$background" \
  -extent "${tonight_w}x${top_h}" "$stage_dir/tonight.png"
magick "$capture_dir/calendar.png" -gravity north -background "$background" \
  -extent "${calendar_w}x${top_h}" "$stage_dir/calendar.png"
magick "$capture_dir/cycle.png" -gravity north -background "$background" \
  -extent "${cycle_w}x${bottom_h}" "$stage_dir/cycle.png"
magick "$capture_dir/eclipses.png" -gravity north -background "$background" \
  -extent "${eclipses_w}x${bottom_h}" "$stage_dir/eclipses.png"

magick -background "$background" "$stage_dir/tonight.png" \
  "$stage_dir/calendar.png" +smush "$gap" "$stage_dir/top.png"
magick -background "$background" "$stage_dir/cycle.png" \
  "$stage_dir/eclipses.png" +smush "$gap" "$stage_dir/bottom.png"
magick -background "$background" "$stage_dir/top.png" "$stage_dir/bottom.png" \
  -smush "$gap" -bordercolor "$background" -border "$border" \
  "$stage_dir/preview.png"

expected_w=$((tonight_w * 2 + gap + border * 2))
expected_h=$((top_h + bottom_h + gap + border * 2))
read -r actual_w actual_h < <(magick identify -format '%w %h\n' "$stage_dir/preview.png")
if (( actual_w != expected_w || actual_h != expected_h )); then
  echo "generate-preview: expected ${expected_w}x${expected_h}, got ${actual_w}x${actual_h}" >&2
  exit 1
fi

cp "$stage_dir/preview.png" "$repo_dir/preview.png"
echo "generate-preview: composed four live captures into ${actual_w}x${actual_h} preview.png"
