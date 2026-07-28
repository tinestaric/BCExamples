#!/usr/bin/env bash
# Offline RDLC render + diff loop, packaged as a Claude Code skill.
# Runs from ANY working directory -- locates its own bcdataset.py / harness /
# pdfdiff.py relative to this script, not the caller's cwd.
#
# Usage: render.sh <layout.rdlc> <dataset.xml> [outdir]
#
# First call for a given outdir captures a baseline (the render "as of now").
# Every later call rasterises the new render and diffs it against that same
# baseline, reporting a per-page changed-pixel count into <outdir>/diff/ --
# this is the "did my layout edit do what I meant" signal. The baseline is
# NOT overwritten automatically; run accept-baseline.sh once a change is
# confirmed correct, so the next edit diffs against the new state instead of
# the original one.
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RDL="${1:?usage: render.sh <layout.rdlc> <dataset.xml> [outdir]}"
XML="${2:?}"
OUT="${3:-render}"

# Not every machine has a working `python3` on PATH -- on Windows, `command -v`
# can find a Microsoft Store "python3" shim that exists but fails to run (e.g.
# a plain Anaconda install only ships python.exe, no python3.exe). Prefer
# python3, but only if it actually executes.
PY=python3
python3 --version >/dev/null 2>&1 || PY=python

"$PY" "$SKILL_DIR/bcdataset.py" "$XML" "$RDL" -o "$OUT"

# Prefer the bundled self-contained exe (harness/publish/win-x64) -- no .NET
# SDK, no `dotnet` on PATH, no installed runtime needed at all. Only falls
# back to `dotnet run` (which DOES need the SDK) if that publish is missing,
# e.g. after pulling harness/ source changes that haven't been republished.
EXE="$SKILL_DIR/harness/publish/win-x64/bcrender.exe"
if [ -f "$EXE" ]; then
  "$EXE" --rdl "$RDL" --data "$OUT/dataset.json" \
         --params "$OUT/parameters.json" --out "$OUT/report.pdf"
else
  echo "no published exe at $EXE -- falling back to 'dotnet run' (requires .NET 8 SDK)" >&2
  dotnet run --project "$SKILL_DIR/harness" -- --rdl "$RDL" --data "$OUT/dataset.json" \
         --params "$OUT/parameters.json" --out "$OUT/report.pdf"
fi

"$PY" "$SKILL_DIR/pdfdiff.py" rasterize "$OUT/report.pdf" --out "$OUT/pages" --dpi 110

if [ -d "$OUT/baseline" ]; then
  echo "--- pixel diff vs baseline (run accept-baseline.sh to promote this render) ---"
  "$PY" "$SKILL_DIR/pdfdiff.py" diff "$OUT/baseline" "$OUT/pages" --out "$OUT/diff"
else
  mkdir -p "$OUT/baseline"; cp "$OUT"/pages/page-*.png "$OUT/baseline/"
  echo "baseline captured ($(ls "$OUT"/baseline | wc -l) pages) -- this is the reference future runs diff against"
fi
