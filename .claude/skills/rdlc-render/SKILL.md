---
name: rdlc-render
description: Render a Business Central/NAV RDLC report layout offline from a captured dataset, and diff the PDF output pixel-by-pixel against a previous render or against BC's own reference PDF. Use this whenever you (the agent) are editing an .rdlc layout in an AL project and need to see whether the edit actually did what was intended, without publishing to a BC server and re-running the report. Triggers on requests like "render this report layout", "check if my RDLC change worked", "preview this BC report", "does this layout still match BC's output".
---

# RDLC offline render + diff loop

No BC server in the path. You (the agent) get to see the actual rendered PDF
after editing a layout, instead of asking the user to publish and re-run the
report in BC every time.

**Before making any structural edit to a Tablix** (adding/removing/reordering
rows or columns, splitting a cell across two lines, swapping which field a
column shows) — read `tablix-editing.md` in this folder first. It's a set of
gotchas about `TablixCell`/`ColSpan` validity, shared column widths, the
overlay-`Rectangle` header pattern, and row-hierarchy members, each
discovered the hard way as a render crash or a truncated field. Skip it for
purely cosmetic edits (font, color, single-textbox alignment).

Use `.\Inspect-Tablix.ps1 <layout.rdlc>` (also in this folder) to check those
gotchas mechanically instead of by hand: `-Validate` catches the cell/span
error *before* you spend a render cycle on it, `-Rows`/`-Columns` map the
structure, `-Find <name>` locates a cell (and flags if it's inside an
overlay Rectangle). Run `-Validate` after every structural edit.

## Install

Project skills are only discovered from the current working directory's
`.claude/skills/`. This folder needs to physically exist inside the AL
project you're working in (or under `~/.claude/skills/` to make it available
in every project). It's self-contained — copy the whole `rdlc-render/`
directory, nothing outside it is referenced:

```
cp -r <this-folder> /path/to/al-project/.claude/skills/rdlc-render
```

That copy is a few hundred KB — `lib/` (the ReportViewer assemblies and the
compiled renderer) is fetched by `bootstrap.ps1` on first use, not committed,
and gitignored. `harness/` in the copy is source only (no `publish/`), kept as
the PS7/Linux/CI fallback.

## What you need before you can use this

Ask the user for these if they aren't already in the project (all obtained
from BC's request page, `Send to` menu, on one representative run — same
report, same filters, all three from the *same* run):

| File | How it's produced in BC | Required? |
| --- | --- | --- |
| `<Layout>.rdlc` | the layout under test, from the AL extension source | yes |
| `<name>.xml` | `Send to > XML Document` | yes — the dataset to render with |
| `<name>.xlsx` | `Send to > Microsoft Excel Document (data only)` | no — only useful as a flattener oracle if you're also touching `bcdataset.ps1`/`bcdataset.py`-style logic, which you shouldn't need to for a normal layout edit |
| `bc-reference.pdf` | `Send to > PDF Document` | no — only needed for an absolute conformance check against production; the baseline/diff workflow below works without it |

If you only have the `.rdlc` and no dataset export, tell the user you need a
`Send to > XML Document` capture from a real (or test) run before you can
render anything -- there is no synthetic-dataset fallback.

**If your layout edit adds or renames a field the dataset doesn't have**,
`bcdataset.ps1` (invoked by `render.ps1`) prints a line like:

```
MISSING (layout wants, dataset lacks): NewField_
```

That means the captured `dataset.xml` is now stale relative to the layout,
not that anything is broken. The render will proceed with that field null or
blank, which will look like a rendering bug but isn't one. **Do not** try to
fix this by hand-editing `bcdataset.ps1` or the dataset XML — get a fresh
`Send to > XML Document` capture (with the AL code that populates the new
field already deployed) and re-render with that.

## Prerequisites (one-time, per machine)

- **Windows PowerShell 5.1** (`powershell.exe`, not `pwsh.exe`/PS7). PS 5.1
  runs on .NET Framework, which can load Microsoft's own ReportViewer 15
  assemblies -- PS 7.x (.NET Core/5+) cannot. `render.ps1` runs
  `bootstrap.ps1` automatically the first time; `bootstrap.ps1` itself checks
  the PowerShell version and stops with a clear message if it's not 5.1.
- **No .NET SDK, no NuGet client, no Python, nothing to install by hand.**
  Every step -- flattening (`bcdataset.ps1`), rendering (`BcRender.cs`),
  rasterising (`Rasterize-BcPdf.ps1`, Windows' own WinRT `Windows.Data.Pdf`),
  diffing (`diff.ps1`, `System.Drawing`) -- is PowerShell or a
  compiled-at-bootstrap `.exe`. `bootstrap.ps1` downloads Microsoft's own
  ReportViewer + SqlServer.Types packages from nuget.org into `lib/`
  (gitignored, ~18 MB), then compiles `lib\bcrender.exe` from `BcRender.cs`
  using `csc.exe`, the .NET Framework 4 compiler bundled with every Windows
  install. If nuget.org isn't reachable, pass `-LibDir <path>` to a folder
  with the same DLLs already in it (e.g. a BC on-prem install's `Service\` +
  `Service\SideServices\` + `Service\SideServices\x64\`, flattened together).
- **Not on Windows, or on PowerShell 7?** Use `harness/` instead (source only
  in this skill copy, no prebuilt binary) — `dotnet run --project harness --
  --rdl ... --data ... --out ...`. Needs the .NET 8 SDK, **and Python 3** with
  `pymupdf`/`pillow` (`pip install pymupdf pillow`) for `pdfdiff.py`, which
  this fallback still uses for rasterising/diffing (WinRT and `csc.exe` are
  Windows-only, so this is the one path that still needs it). `render.sh`,
  `accept-baseline.sh`, `compare-bc.sh` are the bash equivalents of the
  `.ps1` scripts below, driving `harness/` + `bcdataset.py`/`pdfdiff.py`
  instead of `lib\bcrender.exe` + the `.ps1` tooling. On Windows, if
  `python3`/`python` prints "Python was not found; run without arguments to
  install from the Microsoft Store...", a broken Store shim is ahead of the
  real interpreter on PATH -- on some machines this happens for *both*
  names; `render.sh`/`compare-bc.sh` probe both and fall back accordingly.

## The loop

```
.\render.ps1 <layout.rdlc> <dataset.xml> [outdir]      # default outdir: render/
```

- **First call for a given `outdir`:** renders, rasterises to PNG (110 dpi,
  one file per page), and captures that as the baseline. No diff yet -- there's
  nothing to compare against.
- **Every later call with the same `outdir`:** renders again and diffs the new
  pages against the baseline, writing `outdir/diff/page-N.png` (changed pixels
  highlighted red) and `outdir/diff/summary.txt` (a changed-pixel count per
  page). This is the feedback signal: **before editing the layout, run
  render.ps1 once to capture the baseline. Edit the .rdlc. Run render.ps1
  again with the same outdir.** The diff shows exactly what moved, and nothing
  more than that means the edit was surgical; unexpected changes elsewhere
  mean it wasn't.
- Read the resulting `diff/page-N.png` files (the Read tool renders PNGs
  directly) -- don't just look at the changed-pixel count. A big count can be
  one moved textbox; a small count can be a subtly wrong value. Look at the
  image.
- Once you and the user agree a change is correct, run
  `.\accept-baseline.ps1 [outdir]` to promote the current render as the new
  baseline, so the *next* edit diffs against this state, not the original one.

If a `bc-reference.pdf` is available, run
`.\compare-bc.ps1 <outdir> <bc-reference.pdf>` after `render.ps1` to check
conformance against BC's own production rendering (a separate, independent
diff from the running baseline above -- this answers "how far from BC are we",
not "what did my last edit change").

## Reading the diff correctly

**A changed page count outranks any pixel count.** If a layout edit pushes
content onto a new page or removes one, `diff.ps1` prints `NEW PAGE` /
`MISSING PAGE` in the summary instead of a pixel number for that page --
those pages contribute *zero* to the total, so an edit that silently added a
page 3 can report a smaller total than a harmless font tweak. Always check
`diff/summary.txt` for those lines before trusting the total, not just the
number.

Expect nonzero pixel counts even when nothing meaningful changed:

- **A "rendered at" timestamp / username header**, if the layout has one,
  changes every run by definition. Don't chase this to zero.
- **Font-metrics drift** between ReportViewer (the Microsoft one this skill
  drives by default, or the `ReportViewerCore.NETCore` fallback -- both show
  the same drift) and BC's own report server shows up as a small, consistent
  per-glyph offset, especially in right-aligned numeric columns, even when the
  underlying value is identical. If a diff is small, spread evenly across many
  rows of the same column, and the values read the same by eye, that's this,
  not a bug in the edit.
- A change concentrated in one region matching where you edited the layout,
  with nothing highlighted elsewhere, is the good outcome.

This renderer is an inner loop, not an oracle: text measurement differs
slightly from BC's server, so a layout that just barely fits here may overflow
in production, and vice versa. Treat a real BC run as the acceptance gate
before calling a layout change done, especially for anything with a company
logo (both render paths need Windows for this: the PowerShell path always
does, and `harness/`'s `System.Drawing` is unavailable on non-Windows .NET
7+) or tight column widths.

**`BcRender.cs` also has a `--format PNG` mode (renders straight to PNG, no
PDF) -- don't use it.** Nothing in `render.ps1`/`compare-bc.ps1` calls it, and
you shouldn't either: ReportViewer's Image renderer measures text differently
enough from its PDF renderer to change actual pagination -- confirmed on this
skill's own reference fixture (2 pages as PDF, 3 as direct PNG, with a column
wrapping mid-value). A page-count or wrapping difference from that would be
indistinguishable from a real layout defect, which is exactly the "confidently
wrong" failure mode this skill exists to avoid.

## Known fixes already baked into `BcRender.cs` / `harness/`

- `report.EnableHyperlinks = true` / `report.EnableExternalImages = true` are
  set before `Render()` -- without them, the first render throws
  `ReportSecurityException: contains hyperlinks`.
- Thread culture is pinned to the dataset's own `FormatRegion` (recorded in
  `dataset.json`'s `meta`), not the machine's locale. BC ships dates as
  pre-formatted strings and the layout calls `CDate()` on them; rendering
  under the wrong culture can throw or silently parse to the wrong date.
- Columns carrying `decimalformatter` in the XML are typed as `Double`, not
  `string` -- BC layouts frequently `Sum()` these fields, which silently
  concatenates instead of adding if the column arrives as text.
- A `DataItem` is a leaf (one output row) when it has **no `DataItem`
  children**, not when it has no `<DataItems>` tag at all -- BC sometimes
  emits an empty `<DataItems/>` container for a node with no nested
  repeating-group data in a given run (e.g. a ledger entry with no applied
  entries). Getting this wrong silently drops rows to zero rather than
  erroring, so it's easy to miss.
- Columns with no formatter attribute at all whose every observed value is
  the literal string `"True"` or `"False"` are typed `Boolean`, not `string`
  -- layouts commonly gate visibility with
  `=IIF(Fields!SomeFlag.Value, ...)`, which throws
  `input string 'True' was not in a correct format` at render time if that
  arrives as text instead of a real Boolean.

Don't remove any of these five when editing `BcRender.cs`, `harness/Program.cs`,
`bcdataset.ps1` (primary path), or `bcdataset.py` (`harness/` fallback path).
