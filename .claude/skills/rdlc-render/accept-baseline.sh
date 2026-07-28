#!/usr/bin/env bash
# Promote the current render as the new baseline for a given outdir, once a
# layout edit's diff has been reviewed and confirmed correct. Without this,
# render.sh keeps diffing against whatever render came first.
#
# Usage: accept-baseline.sh [outdir]
set -euo pipefail
OUT="${1:-render}"

[ -d "$OUT/pages" ] || { echo "no $OUT/pages -- run render.sh first" >&2; exit 1; }

rm -rf "$OUT/baseline"
mkdir -p "$OUT/baseline"
cp "$OUT"/pages/page-*.png "$OUT/baseline/"
echo "baseline promoted from $OUT/pages ($(ls "$OUT"/baseline | wc -l) pages)"
