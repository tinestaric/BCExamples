#!/usr/bin/env python3
"""PDF -> per-page PNG rasterisation and pixel diffing, no native binaries.

Replaces render.sh's pdftoppm + ImageMagick `compare` calls with pymupdf +
pillow so the loop runs the same on Windows and Linux.

  pdfdiff.py rasterize report.pdf --out render --dpi 110
      -> render/page-1.png, render/page-2.png, ...

  pdfdiff.py diff baseline/ render/ --out render/diff
      -> render/diff/page-N.png (highlighted diff) + render/diff/summary.txt
         with a changed-pixel count per page.
"""
import argparse
import sys
from pathlib import Path

import fitz  # pymupdf
from PIL import Image, ImageChops


def rasterize(pdf_path: Path, out_dir: Path, dpi: int) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    zoom = dpi / 72.0
    mat = fitz.Matrix(zoom, zoom)
    written = []
    with fitz.open(pdf_path) as doc:
        for i, page in enumerate(doc, start=1):
            pix = page.get_pixmap(matrix=mat)
            path = out_dir / f"page-{i}.png"
            pix.save(path)
            written.append(path)
    return written


def diff_pair(baseline_png: Path, candidate_png: Path, diff_png: Path) -> int:
    """Highlighted diff of two same-page PNGs. Returns changed-pixel count."""
    a = Image.open(baseline_png).convert("RGB")
    b = Image.open(candidate_png).convert("RGB")
    if a.size != b.size:
        # Different page sizes: pad to the union so diff still produces
        # something visual instead of throwing.
        w = max(a.width, b.width)
        h = max(a.height, b.height)
        pa = Image.new("RGB", (w, h), "white"); pa.paste(a, (0, 0))
        pb = Image.new("RGB", (w, h), "white"); pb.paste(b, (0, 0))
        a, b = pa, pb

    delta = ImageChops.difference(a, b)
    mask = delta.convert("L").point(lambda p: 255 if p > 0 else 0)
    changed = mask.histogram()[255]  # mask is binary: 0 or 255 only

    # Highlight: candidate image dimmed, changed pixels painted red.
    highlighted = b.copy()
    red = Image.new("RGB", b.size, (255, 0, 0))
    highlighted = Image.composite(red, highlighted, mask)
    highlighted.save(diff_png)
    return changed


def cmd_rasterize(args):
    pages = rasterize(Path(args.pdf), Path(args.out), args.dpi)
    print(f"wrote {len(pages)} page(s) -> {args.out}")


def cmd_diff(args):
    baseline_dir = Path(args.baseline)
    candidate_dir = Path(args.candidate)
    diff_dir = Path(args.out)
    diff_dir.mkdir(parents=True, exist_ok=True)

    baseline_pages = sorted(baseline_dir.glob("page-*.png"),
                            key=lambda p: int(p.stem.split("-")[1]))
    candidate_pages = sorted(candidate_dir.glob("page-*.png"),
                             key=lambda p: int(p.stem.split("-")[1]))
    baseline_names = {p.name for p in baseline_pages}
    candidate_names = {p.name for p in candidate_pages}

    summary_lines = []
    total_changed = 0
    any_page = False
    page_count_changed = False

    for name in sorted(candidate_names | baseline_names,
                       key=lambda n: int(n.split("-")[1].split(".")[0])):
        any_page = True
        if name not in baseline_names:
            summary_lines.append(f"WARNING: NEW PAGE {name} (not in baseline -- contributes 0 to the pixel total below, but is not a clean diff)")
            page_count_changed = True
            continue
        if name not in candidate_names:
            summary_lines.append(f"WARNING: MISSING PAGE {name} (present in baseline, not in candidate -- contributes 0 to the pixel total below, but is not a clean diff)")
            page_count_changed = True
            continue
        changed = diff_pair(baseline_dir / name, candidate_dir / name, diff_dir / name)
        total_changed += changed
        summary_lines.append(f"{changed:>10} changed px  <- {name}")

    summary_lines.append(f"{total_changed:>10} changed px  <- TOTAL")
    if page_count_changed:
        summary_lines.append(
            "WARNING: page count differs between baseline and candidate -- "
            "the pixel total above does NOT reflect the full change. See the "
            "NEW PAGE / MISSING PAGE lines.")
    summary_text = "\n".join(summary_lines) + "\n"
    (diff_dir / "summary.txt").write_text(summary_text)
    print(summary_text, end="")
    if not any_page:
        print("no pages found in either directory", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_rast = sub.add_parser("rasterize", help="PDF -> per-page PNGs")
    p_rast.add_argument("pdf")
    p_rast.add_argument("--out", required=True)
    p_rast.add_argument("--dpi", type=int, default=110)
    p_rast.set_defaults(func=cmd_rasterize)

    p_diff = sub.add_parser("diff", help="diff two directories of page-N.png")
    p_diff.add_argument("baseline")
    p_diff.add_argument("candidate")
    p_diff.add_argument("--out", required=True)
    p_diff.set_defaults(func=cmd_diff)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
