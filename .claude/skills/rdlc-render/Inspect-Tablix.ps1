<#
.SYNOPSIS
  Static introspection + validation for a Tablix in an .rdlc, so a structural
  layout edit (add/remove/reorder rows or columns, split a cell, swap which
  field a column shows) can be planned and checked BEFORE spending a render
  cycle on it. See tablix-editing.md for the gotchas this exists to catch.

.DESCRIPTION
  Modes (combine freely; default with no switch is -Validate):

    -Rows       Dump every row: cell index, textbox Name (or the names inside
                an overlay Rectangle, if the cell holds one instead of a
                Textbox directly -- see tablix-editing.md #3), and ColSpan.

    -Columns    Dump each TablixColumn's Width, plus which (row, textbox
                Name) pairs have REAL (non-spanned) content at that column
                index -- this is the "widths are shared by every row" check:
                before resizing a column, see everything else that lives
                there.

    -Validate   Walk every row and check the span-coverage rule: every cell
                needs CellContents, unless an earlier cell in the same row
                has a ColSpan reaching it. Reports every violation with row/
                column index. Exit code 1 if any violation found -- this is
                exactly the error class that otherwise only surfaces as a
                render-time ReportPublishingException.

    -Find NAME  Locate a Textbox by its Name attribute anywhere under the
                tablix (including inside an overlay Rectangle). Reports
                whether it's a normal grid cell (row/column index, ColSpan)
                or lives inside a free-positioned Rectangle overlay (Left/
                Top/Width), plus its Value expression(s), Format, and
                TextAlign -- everything needed to plan an edit without a
                separate ad-hoc script.

.PARAMETER RdlPath
  Path to the .rdlc layout.

.PARAMETER TablixName
  Which Tablix to inspect, if the layout has more than one. Optional when
  there's exactly one (the common case) -- otherwise required, and omitting
  it lists the names found and stops.

.EXAMPLE
  .\Inspect-Tablix.ps1 CustomerAccountDetail.rdlc -Validate

.EXAMPLE
  .\Inspect-Tablix.ps1 CustomerAccountDetail.rdlc -Rows

.EXAMPLE
  .\Inspect-Tablix.ps1 CustomerAccountDetail.rdlc -Columns

.EXAMPLE
  .\Inspect-Tablix.ps1 CustomerAccountDetail.rdlc -Find Cust__Ledger_Entry__Posting_Date_
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)] [string]$RdlPath,
    [string]$TablixName,
    [switch]$Rows,
    [switch]$Columns,
    [switch]$Validate,
    [string]$Find
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Xml.Linq

$RdlNs = [System.Xml.Linq.XNamespace]'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'

function Get-Tablix {
    $doc = [System.Xml.Linq.XDocument]::Load($RdlPath)
    $all = @($doc.Descendants($RdlNs + 'Tablix'))
    if ($all.Count -eq 0) { throw "no <Tablix> found in $RdlPath" }
    if ($TablixName) {
        $match = $all | Where-Object { $_.Attribute('Name').Value -eq $TablixName }
        if (-not $match) {
            $names = ($all | ForEach-Object { $_.Attribute('Name').Value }) -join ', '
            throw "no Tablix named '$TablixName' -- found: $names"
        }
        return $match
    }
    if ($all.Count -gt 1) {
        $names = ($all | ForEach-Object { $_.Attribute('Name').Value }) -join ', '
        throw "layout has $($all.Count) Tablixes ($names) -- pass -TablixName"
    }
    return $all[0]
}

# A cell's content might be a Textbox directly, or a Rectangle wrapping
# several absolutely-positioned Textboxes (the two-line dotted-header
# overlay pattern -- see tablix-editing.md #3). Returns a list of
# [pscustomobject]@{ Name; Textbox; IsOverlay; Rectangle } -- empty if the
# cell has no CellContents at all.
function Get-CellTextboxes($tablixCell) {
    $cc = $tablixCell.Element($RdlNs + 'CellContents')
    if (-not $cc) { return @() }
    $direct = $cc.Element($RdlNs + 'Textbox')
    if ($direct) {
        return , [pscustomobject]@{ Name = $direct.Attribute('Name').Value; Textbox = $direct; IsOverlay = $false; Rectangle = $null }
    }
    $rect = $cc.Element($RdlNs + 'Rectangle')
    if ($rect) {
        $items = $rect.Element($RdlNs + 'ReportItems')
        if ($items) {
            return @($items.Elements($RdlNs + 'Textbox') | ForEach-Object {
                [pscustomobject]@{ Name = $_.Attribute('Name').Value; Textbox = $_; IsOverlay = $true; Rectangle = $rect }
            })
        }
    }
    return @()
}

function Get-ColSpan($tablixCell) {
    $cc = $tablixCell.Element($RdlNs + 'CellContents')
    if (-not $cc) { return 1 }
    $cs = $cc.Element($RdlNs + 'ColSpan')
    if ($cs) { return [int]$cs.Value }
    return 1
}

function Get-Rows($tablix) {
    $rowsEl = $tablix.Descendants($RdlNs + 'TablixRows') | Select-Object -First 1
    if (-not $rowsEl) { throw "Tablix '$($tablix.Attribute('Name').Value)' has no TablixRows" }
    return @($rowsEl.Elements($RdlNs + 'TablixRow'))
}

function Get-Columns($tablix) {
    $colsEl = $tablix.Descendants($RdlNs + 'TablixColumns') | Select-Object -First 1
    if (-not $colsEl) { throw "Tablix '$($tablix.Attribute('Name').Value)' has no TablixColumns" }
    return @($colsEl.Elements($RdlNs + 'TablixColumn'))
}

function Format-CellSummary($tablixCell) {
    $tbs = Get-CellTextboxes $tablixCell
    if ($tbs.Count -eq 0) { return '-' }
    $colspan = Get-ColSpan $tablixCell
    $names = ($tbs | ForEach-Object { $_.Name }) -join ', '
    if ($tbs[0].IsOverlay) { return "[Rectangle: $names]" }
    if ($colspan -gt 1) { return "$names (ColSpan=$colspan)" }
    return $names
}

function Invoke-Rows($tablix) {
    $rowList = Get-Rows $tablix
    Write-Host "Tablix '$($tablix.Attribute('Name').Value)': $($rowList.Count) rows"
    for ($i = 0; $i -lt $rowList.Count; $i++) {
        $cells = @($rowList[$i].Descendants($RdlNs + 'TablixCells') | Select-Object -First 1 | ForEach-Object { $_.Elements($RdlNs + 'TablixCell') })
        $summaries = for ($c = 0; $c -lt $cells.Count; $c++) { "[$c]$(Format-CellSummary $cells[$c])" }
        Write-Host "  row $i ($($cells.Count) cells): $($summaries -join '  ')"
    }
}

function Invoke-Columns($tablix) {
    $colList = Get-Columns $tablix
    $rowList = Get-Rows $tablix
    Write-Host "Tablix '$($tablix.Attribute('Name').Value)': $($colList.Count) columns"
    for ($ci = 0; $ci -lt $colList.Count; $ci++) {
        $width = $colList[$ci].Element($RdlNs + 'Width')
        Write-Host "  col $ci  width=$(if ($width) { $width.Value } else { '(none)' })"
        for ($ri = 0; $ri -lt $rowList.Count; $ri++) {
            $cells = @($rowList[$ri].Descendants($RdlNs + 'TablixCells') | Select-Object -First 1 | ForEach-Object { $_.Elements($RdlNs + 'TablixCell') })
            if ($ci -ge $cells.Count) { continue }
            $tbs = Get-CellTextboxes $cells[$ci]
            if ($tbs.Count -gt 0) {
                $names = ($tbs | ForEach-Object { $_.Name }) -join ', '
                Write-Host "      row $ri : $names"
            }
        }
    }
    Write-Host ""
    Write-Host "NOTE: every row above shares these same column widths. Before resizing" -ForegroundColor Yellow
    Write-Host "a column, check every row listed under it fits the new width." -ForegroundColor Yellow
}

function Invoke-Validate($tablix) {
    $rowList = Get-Rows $tablix
    $violations = New-Object System.Collections.Generic.List[string]
    for ($ri = 0; $ri -lt $rowList.Count; $ri++) {
        $cells = @($rowList[$ri].Descendants($RdlNs + 'TablixCells') | Select-Object -First 1 | ForEach-Object { $_.Elements($RdlNs + 'TablixCell') })
        $coveredUntil = -1
        for ($ci = 0; $ci -lt $cells.Count; $ci++) {
            $cc = $cells[$ci].Element($RdlNs + 'CellContents')
            if (-not $cc) {
                if ($ci -gt $coveredUntil) {
                    $violations.Add("row $ri, col $ci -- empty cell not covered by a span from an earlier cell in the row")
                }
                continue
            }
            $span = Get-ColSpan $cells[$ci]
            if ($ci + $span - 1 -gt $coveredUntil) { $coveredUntil = $ci + $span - 1 }
        }
    }
    if ($violations.Count -eq 0) {
        Write-Host "OK: Tablix '$($tablix.Attribute('Name').Value)' -- $($rowList.Count) rows, all cell/span coverage valid"
        return $true
    }
    Write-Host "INVALID: Tablix '$($tablix.Attribute('Name').Value)' -- $($violations.Count) span-coverage violation(s):" -ForegroundColor Red
    foreach ($v in $violations) { Write-Host "  $v" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Fix: give each listed cell real (blank-value) CellContents, or extend a" -ForegroundColor Yellow
    Write-Host "preceding cell's ColSpan to cover it. See tablix-editing.md #1." -ForegroundColor Yellow
    return $false
}

function Invoke-Find($tablix, [string]$name) {
    $rowList = Get-Rows $tablix
    $found = $false
    for ($ri = 0; $ri -lt $rowList.Count; $ri++) {
        $cells = @($rowList[$ri].Descendants($RdlNs + 'TablixCells') | Select-Object -First 1 | ForEach-Object { $_.Elements($RdlNs + 'TablixCell') })
        for ($ci = 0; $ci -lt $cells.Count; $ci++) {
            $tbs = Get-CellTextboxes $cells[$ci]
            $hit = $tbs | Where-Object { $_.Name -eq $name }
            if (-not $hit) { continue }
            $found = $true
            $tb = $hit.Textbox
            $valueEls = @($tb.Descendants($RdlNs + 'Value'))
            $values = ($valueEls | ForEach-Object { $_.Value }) -join ' | '
            $formatEl = $tb.Descendants($RdlNs + 'Format') | Select-Object -First 1
            $alignEl = $tb.Descendants($RdlNs + 'TextAlign') | Select-Object -First 1
            $colspan = Get-ColSpan $cells[$ci]

            Write-Host "Found '$name' in row $ri, column $ci"
            if ($hit.IsOverlay) {
                $left = $tb.Element($RdlNs + 'Left')
                $top = $tb.Element($RdlNs + 'Top')
                $width = $tb.Element($RdlNs + 'Width')
                Write-Host "  OVERLAY: inside a Rectangle in this cell, absolutely positioned" -ForegroundColor Yellow
                Write-Host "  Left=$(if ($left) { $left.Value } else { '(default 0)' })  Top=$(if ($top) { $top.Value } else { '(default 0)' })  Width=$(if ($width) { $width.Value } else { '(auto)' })"
                Write-Host "  Moving/resizing the tablix column here will NOT move this -- reposition it separately. See tablix-editing.md #3." -ForegroundColor Yellow
            }
            else {
                Write-Host "  GRID cell, ColSpan=$colspan"
            }
            Write-Host "  Value(s): $values"
            if ($formatEl) { Write-Host "  Format: $($formatEl.Value)" }
            if ($alignEl) { Write-Host "  TextAlign: $($alignEl.Value)" }
        }
    }
    if (-not $found) {
        Write-Host "'$name' not found in Tablix '$($tablix.Attribute('Name').Value)'" -ForegroundColor Red
        return $false
    }
    return $true
}

# --- main --------------------------------------------------------------

$tablix = Get-Tablix
$ranAnything = $false
$ok = $true

if ($Rows) { Invoke-Rows $tablix; $ranAnything = $true }
if ($Columns) { Invoke-Columns $tablix; $ranAnything = $true }
if ($Find) { $ok = (Invoke-Find $tablix $Find) -and $ok; $ranAnything = $true }
if ($Validate -or -not $ranAnything) { $ok = (Invoke-Validate $tablix) -and $ok }

if (-not $ok) { exit 1 }
