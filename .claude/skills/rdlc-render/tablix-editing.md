# Editing Tablix layouts — hard-won gotchas

Read this before making any structural edit to a `.rdlc`'s `Tablix` (adding/
removing/reordering rows or columns, splitting a cell across two lines,
swapping which field a column shows). Cosmetic edits (font size, color, a
single textbox's alignment) don't need this — it's for anything that touches
row/column/cell *structure*.

These were each discovered the hard way, as a render-time crash or a
truncated/misaligned field, on a real BC-generated layout
(`CustomerAccountDetail.rdlc`). Treat them as established.

**Use `Inspect-Tablix.ps1` (in this folder) instead of re-deriving any of
this by hand** — it implements the checks below directly:

```
.\Inspect-Tablix.ps1 <layout.rdlc> -Validate            # rule #1, before you render
.\Inspect-Tablix.ps1 <layout.rdlc> -Rows                # structural map: every row's cells, names, ColSpans
.\Inspect-Tablix.ps1 <layout.rdlc> -Columns              # rule #2: widths + which rows use each column
.\Inspect-Tablix.ps1 <layout.rdlc> -Find <textboxName>   # locate a cell, incl. rule #3's Rectangle overlays
```

Run `-Validate` after every structural edit, before spending a render cycle
on it. It exits 1 and prints exactly which row/column is broken if rule #1
is violated — that used to only surface as a render-time
`ReportPublishingException`.

## 1. An empty `<TablixCell/>` is only legal if a span covers it

Every column position in every row needs either real `CellContents`, or to be
covered by a `ColSpan`/`RowSpan` from another cell. There is no "just leave it
blank" — a bare `<TablixCell />` with nothing covering it fails at render
time with:

```
ReportPublishingException: The tablix 'Table1' has an invalid TablixCell.
The CellContents for this TablixCell is required if not covered by a span
from another TablixCell.
```

Concretely:
- If you delete a cell's content to "blank it out", give it a real (blank
  `<Value></Value>`) Textbox instead of a self-closing `<TablixCell />`,
  *unless* a neighboring cell's `ColSpan` already reaches it.
- If you remove or shrink a `ColSpan` on some cell, check whether any
  now-uncovered position downstream still has a bare `<TablixCell />` — it
  was relying on that span.
- Before rendering a structural change, walk every row and verify: for each
  cell index, either it has `CellContents`, or an earlier cell in the same
  row has `ColSpan` reaching that index. Catching this by inspection is much
  faster than a render-crash-fix-retry loop (this bit the same session twice).

## 2. `TablixColumn` widths are global — shared by every row at that index

A Tablix has one `TablixColumns` list for the whole table. Column 0's width
applies to **every** row's cell at index 0, not just the row you're editing.
BC layouts routinely reuse the same columns for unrelated content across
different static rows (e.g. column 0 might hold `Customer No.` on one row,
a ledger entry's `Posting Date` on another, and a totals-section date on a
third — three semantically unrelated fields sharing one column slot).

Consequences:
- Resizing a column to fit one row's content can truncate a completely
  different field on another row that happens to share that column index.
  Before changing any `TablixColumn` width, list every row that has real
  content at that column index and check each one's likely text length
  against the new width.
- "Swap column A and column B" generally means swapping both the *content*
  (which field/value is shown) **and** the *width* at that index — content
  alone leaves whichever field has the longer natural text truncated in the
  other's old, narrower slot. Symptom: a date rendering as `1/18/20` instead
  of `1/18/2023` — the string wasn't wrong, the column was just too narrow
  for what got moved into it.

## 3. Grouped "dotted underline" headers are drawn outside the grid

BC's stock layouts (Customer/Vendor Ledger Entries and similar) often have a
two-line header: a top line of wide group labels ("Customer", "Document",
"Net Change") with a dotted rule, and a second line of per-column captions
("Date", "Type", "Number", ...). These are **not** two `TablixRow`s with
per-column cells. Instead, one row's cell contains a `Rectangle` with several
absolutely-positioned Textboxes (`Left`/`Top`/`Width` on each one), fully
independent of the tablix's column grid. The dotted line is just a
`TopBorder: Dotted` style on the *second-line* textboxes, not a drawn line
element.

Implications:
- Don't assume a per-column header caption lives in a normal grid cell at
  that column's index — check for a `Rectangle` wrapper with nested
  `ReportItems` first. `grep`/search for the field's caption name
  (e.g. `DateCaption`) to find it regardless of nesting.
- If you swap or resize columns that a header rectangle's textboxes are
  positioned over, you must move those textboxes' `Left`/`Width` too — they
  won't follow the grid automatically, because they were never tied to it.

## 4. Adding a physical row needs a matching hierarchy member

A Tablix's rows aren't just `TablixRows` — there's a parallel
`TablixRowHierarchy` tree of `TablixMember` nodes that must have exactly one
member per physical row (nested to match any row groups). Insert a new
`TablixRow` without a corresponding sibling `TablixMember` in the right place
in the hierarchy, and the row count won't match what the report engine
expects.

For a simple **static** row (no grouping expression of its own) sitting
alongside another static row in the same group, the fix is mechanical:
duplicate the neighboring row's trivial member —

```xml
<TablixMember>
  <KeepWithGroup>After</KeepWithGroup>
  <KeepTogether>true</KeepTogether>
</TablixMember>
```

— as a new sibling in the same `TablixMembers` list, in the same relative
position as the new `TablixRow`.

## 5. Practical editing notes

- **Verify anchors are unique before using them.** When locating a cell/
  textbox by name to edit via text search (e.g. `$content.IndexOf($anchor)`
  or a regex), always check the anchor occurs exactly once first — `-Find`
  in `Inspect-Tablix.ps1` does this implicitly by matching on the `Name`
  attribute, which is unique per report; don't assume an arbitrary substring
  is.
- **Move/swap whole blocks, not fragments.** Extract the complete
  `<TablixCell>...</TablixCell>` (or `<Textbox>...</Textbox>`) and
  relocate/swap it wholesale, rather than editing fragments in place — far
  less likely to leave the XML structurally inconsistent.
- **Validate XML after every edit** before spending a render cycle on it —
  `[System.Xml.Linq.XDocument]::Load($path)` (wrap in try/catch) catches
  unbalanced tags for free, same as `bcdataset.ps1` already does when
  reading a dataset/layout.
- **RDLC files usually carry a UTF-8 BOM.** `[System.IO.File]::ReadAllText`
  auto-detects and strips it; when writing the file back, preserve it with
  `[System.IO.File]::WriteAllText($path, $content, (New-Object
  System.Text.UTF8Encoding($true)))` — note the `$true` (emit BOM), the
  opposite of the `$utf8NoBom` this skill's own generated *output* files
  (`dataset.json`, etc.) use.
- **After any structural change, run `.\Inspect-Tablix.ps1 <layout.rdlc>
  -Validate`** (rule #1) before rendering — it's the single most common
  failure mode of this kind of edit, and it's now a one-line check instead
  of a manual row-by-row walk.
