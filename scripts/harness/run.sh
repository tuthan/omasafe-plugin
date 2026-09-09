#!/usr/bin/env bash
# Chart-component acceptance harness (doc 08 CH1-CH10, v0.3.1 T2 / T11).
#
# `qmllint` does not catch a missing QtQuick.Controls import or a bad kit-property
# assign, and it cannot tell whether a 1-of-33 segment is visible at base 9. This
# renders UnitStrip, MeterBar and RankedBars once per (theme, base size) pair and
# writes a PNG per pair.
#
# It never touches the live desktop theme: a scratch HOME carries the
# `.local/state/omarchy/current/theme` symlink the Color singleton reads, and the
# kit modules are symlinked into a scratch config root so `qs.Commons` / `qs.Ui`
# resolve to their own singleton instances.
#
#   scripts/harness/run.sh                       # five themes x four base sizes
#   scripts/harness/run.sh white oxocarbon       # named themes only
#
# Output: $TMPDIR/omasafe-harness/out/<theme>-base<n>.png
set -u

repo=$(cd -- "$(dirname -- "$0")/../.." && pwd)
kit=${OMARCHY_SHELL:-/usr/share/omarchy/shell}
work=${TMPDIR:-/tmp}/omasafe-harness
out=$work/out
themes=("$@")
[ ${#themes[@]} -eq 0 ] && themes=(white catppuccin-latte retro-82 oxocarbon ame-quattro)

[ -d "$kit" ] || { echo "kit not found: $kit (set OMARCHY_SHELL)" >&2; exit 1; }
command -v quickshell >/dev/null || { echo "quickshell not on PATH" >&2; exit 1; }

mkdir -p "$out"
cp "$repo/scripts/harness/charts.qml" "$work/shell.qml"
ln -sfn "$repo/components" "$work/components"
ln -sfn "$repo/model"      "$work/model"
ln -sfn "$kit/Commons"     "$work/Commons"
ln -sfn "$kit/Ui"          "$work/Ui"

find_theme() {
  for d in "$HOME/.config/omarchy/themes/$1" "/usr/share/omarchy/themes/$1"; do
    [ -d "$d" ] && { printf '%s\n' "$d"; return 0; }
  done
  return 1
}

status=0
for theme in "${themes[@]}"; do
  tp=$(find_theme "$theme") || { echo "SKIP $theme (not installed)"; continue; }
  fake=$work/home/$theme
  mkdir -p "$fake/.local/state/omarchy/current" "$fake/.config/omarchy"
  ln -sfn "$tp" "$fake/.local/state/omarchy/current/theme"
  printf '%s\n' "$theme" > "$fake/.local/state/omarchy/current/theme.name"
  for base in 9 12 16 20; do
    png=$out/${theme}-base${base}.png
    log=$out/${theme}-base${base}.log
    rm -f "$png"
    HOME=$fake HARNESS_BASE=$base HARNESS_OUT=$png \
      timeout 30 quickshell -p "$work/shell.qml" >"$log" 2>&1
    if [ -s "$png" ]; then
      echo "OK   $theme base$base  $png"
    else
      echo "FAIL $theme base$base"; tail -5 "$log"; status=1
    fi
  done
done
exit $status
