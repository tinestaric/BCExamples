#!/usr/bin/env bash
# Conformance check: diff the current render against a PDF BC itself produced
# for the same report/dataset/filter. Independent of the running baseline in
# render.sh -- this is "how far from production", not "what did my edit do".
#
# Usage: compare-bc.sh <outdir> <bc-reference.pdf>
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OUT="${1:?usage: compare-bc.sh <outdir> <bc-reference.pdf>}"
BC_PDF="${2:?}"

[ -d "$OUT/pages" ] || { echo "no $OUT/pages -- run render.sh first" >&2; exit 1; }

PY=python3
python3 --version >/dev/null 2>&1 || PY=python

"$PY" "$SKILL_DIR/pdfdiff.py" rasterize "$BC_PDF" --out "$OUT/bc-pages" --dpi 110
echo "--- conformance diff: our render vs $BC_PDF ---"
"$PY" "$SKILL_DIR/pdfdiff.py" diff "$OUT/bc-pages" "$OUT/pages" --out "$OUT/conformance-diff"
