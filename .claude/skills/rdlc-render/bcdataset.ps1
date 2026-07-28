<#
.SYNOPSIS
  Flatten a Business Central report dataset (SaveAsXml / "Send to > XML
  Document") into the flat DataSet_Result table an RDLC layout expects.
  Pure-PowerShell port of bcdataset.py -- see CLAUDE.md's "The flattening
  rules" section for the six rules this implements; they were derived
  empirically and verified against BC's own Excel export, and are ported
  here 1:1, not re-derived.

.DESCRIPTION
  Usage:
      .\bcdataset.ps1 dataset.xml layout.rdlc -OutDir out
        -> out\dataset.json, out\dataset.csv, out\parameters.json

  Three PS 5.1 correctness traps this script deliberately works around (each
  would silently corrupt output, not throw):
    - ConvertTo-Json defaults to -Depth 2 and would flatten `rows` to
      "System.Object[]" strings -- always pass an explicit, generous -Depth.
    - Set-Content -Encoding UTF8 writes a BOM -- BC's own tools and this
      loop's other readers don't expect one, so write via
      [System.IO.File]::WriteAllText with a BOM-less UTF8Encoding.
    - Rows are built as [ordered]@{} with keys only for columns actually
      present on that row (never padded with $null during flattening,
      exactly like bcdataset.py's partial dicts) -- a column absent from a
      row's hashtable must stay absent (-> $null once padded for JSON), never
      coerced to "". Rule 3 (absent != blank) is load-bearing: the layout
      filters a tablix group on a field being null, and collapsing the
      absent/blank distinction moves the totals rows.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)] [string]$XmlPath,
    [Parameter(Position = 1)] [string]$RdlPath,
    [string]$OutDir = '.'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Xml.Linq

$RdlNs = [System.Xml.Linq.XNamespace]'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'
$FormatterAttrs = @('decimalformatter', 'dateformatter', 'timeformatter', 'datetimeformatter')

function Get-RdlFields([string]$rdlPath) {
    $doc = [System.Xml.Linq.XDocument]::Load($rdlPath)
    $ds = $doc.Descendants($RdlNs + 'DataSet') | Select-Object -First 1
    if (-not $ds) { throw "no DataSet found in layout" }
    $fields = @($ds.Descendants($RdlNs + 'Field') | ForEach-Object { $_.Attribute('Name').Value })
    return [pscustomobject]@{ DatasetName = $ds.Attribute('Name').Value; Fields = $fields }
}

function Get-RdlParameters([string]$rdlPath) {
    $doc = [System.Xml.Linq.XDocument]::Load($rdlPath)
    $out = New-Object System.Collections.Generic.List[object]
    foreach ($p in $doc.Descendants($RdlNs + 'ReportParameter')) {
        $default = $null
        $dv = $p.Element($RdlNs + 'DefaultValue')
        if ($dv) {
            $vals = @($dv.Descendants($RdlNs + 'Value') | ForEach-Object { $_.Value })
            if ($vals.Count -gt 0) { $default = $vals[0] }
        }
        $typeEl = $p.Element($RdlNs + 'DataType')
        $out.Add([pscustomobject]@{
            Name    = $p.Attribute('Name').Value
            Type    = if ($typeEl) { $typeEl.Value } else { 'String' }
            Default = $default
        })
    }
    return $out
}

function Get-ColumnsOfNode($node, [System.Collections.Generic.List[string]]$order, [System.Collections.Generic.HashSet[string]]$seen) {
    $out = [ordered]@{}
    $colsEl = $node.Element('Columns')
    if (-not $colsEl) { return $out }
    foreach ($col in $colsEl.Elements('Column')) {
        $name = $col.Attribute('name').Value
        $out[$name] = $col.Value  # XElement.Value is "" for an empty element, matching Python's `col.text or ""`.
        if ($seen.Add($name)) { $order.Add($name) | Out-Null }
        foreach ($attr in $FormatterAttrs) {
            $a = $col.Attribute($attr)
            if ($a) {
                $fname = $name + 'Format'
                $out[$fname] = $a.Value
                if ($seen.Add($fname)) { $order.Add($fname) | Out-Null }
            }
        }
    }
    return $out
}

function Get-FlattenedDataset([string]$xmlPath) {
    $doc = [System.Xml.Linq.XDocument]::Load($xmlPath)
    $root = $doc.Root

    $labels = [ordered]@{}
    $labelsEl = $root.Element('Labels')
    if ($labelsEl) {
        foreach ($lab in $labelsEl.Elements('Label')) {
            $labels[$lab.Attribute('name').Value] = $(if ($null -ne $lab.Value) { $lab.Value } else { '' })
        }
    }

    $order = New-Object System.Collections.Generic.List[string]
    $seen = New-Object System.Collections.Generic.HashSet[string]
    $rows = New-Object System.Collections.Generic.List[object]

    function Walk($container) {
        foreach ($node in $container.Elements('DataItem')) {
            $merged = [ordered]@{}
            foreach ($k in $script:CurrentInherited.Keys) { $merged[$k] = $script:CurrentInherited[$k] }
            $own = Get-ColumnsOfNode $node $order $seen
            foreach ($k in $own.Keys) { $merged[$k] = $own[$k] }

            $kids = $node.Element('DataItems')
            $kidItems = $null
            if ($kids) { $kidItems = @($kids.Elements('DataItem')) }

            # A leaf is "no DataItem children", NOT "no <DataItems> tag" -- BC
            # sometimes emits an empty <DataItems/> container on a node with
            # no nested repeating-group data for a given run. Treating
            # "container present but empty" as "has children" silently drops
            # the row entirely.
            if (-not $kids -or -not $kidItems -or $kidItems.Count -eq 0) {
                $rows.Add($merged) | Out-Null
            }
            else {
                $prevInherited = $script:CurrentInherited
                $script:CurrentInherited = $merged
                Walk $kids
                $script:CurrentInherited = $prevInherited
            }
        }
    }

    $top = $root.Element('DataItems')
    if (-not $top) { throw "no <DataItems> in dataset xml" }
    $script:CurrentInherited = [ordered]@{}
    Walk $top

    return [pscustomobject]@{ Rows = $rows; Order = $order; Labels = $labels }
}

# --- main --------------------------------------------------------------

$flat = Get-FlattenedDataset $XmlPath
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if ($RdlPath) {
    $rdlFields = Get-RdlFields $RdlPath
    $datasetName = $rdlFields.DatasetName
    $columns = $rdlFields.Fields
    $discoveredSet = New-Object System.Collections.Generic.HashSet[string]
    foreach ($c in $flat.Order) { $discoveredSet.Add($c) | Out-Null }
    $columnsSet = New-Object System.Collections.Generic.HashSet[string]
    foreach ($c in $columns) { $columnsSet.Add($c) | Out-Null }

    $missing = @($columns | Where-Object { -not $discoveredSet.Contains($_) })
    $extra = @($flat.Order | Where-Object { -not $columnsSet.Contains($_) })

    Write-Host "dataset name in layout : $datasetName"
    Write-Host "layout declares        : $($columns.Count) fields"
    Write-Host "dataset supplies       : $($flat.Order.Count) columns"
    if ($missing.Count -gt 0) { Write-Host "MISSING (layout wants, dataset lacks): $($missing -join ', ')" }
    if ($extra.Count -gt 0) { Write-Host "unused (dataset has, layout ignores) : $($extra -join ', ')" }

    $params = Get-RdlParameters $RdlPath
    $paramsOut = [ordered]@{}
    foreach ($p in $params) {
        if ($flat.Labels.Contains($p.Name)) {
            $value = $flat.Labels[$p.Name]
            $src = 'Labels'
        }
        else {
            $value = $(if ($null -ne $p.Default) { $p.Default } else { '' })
            $src = 'RDL default'
        }
        $paramsOut[$p.Name] = $value
        Write-Host "parameter $($p.Name) = '$value'  (from $src)"
    }
    $paramsJson = ConvertTo-Json $paramsOut -Depth 10
    [System.IO.File]::WriteAllText((Join-Path $OutDir 'parameters.json'), $paramsJson, $utf8NoBom)
}
else {
    $datasetName = 'DataSet_Result'
    $columns = @($flat.Order)
}

# Column typing. decimalformatter is the reliable signal for "this is a
# decimal" -- BC hands the renderer typed columns, and Sum() on a text
# column silently concatenates instead of adding.
$numeric = New-Object System.Collections.Generic.HashSet[string]
foreach ($c in $columns) {
    if ($c.EndsWith('Format')) { $numeric.Add($c.Substring(0, $c.Length - 6)) | Out-Null }
}

# Booleans carry no formatter attribute at all -- the XML gives no typed
# signal, unlike decimals. BC always serialises them as the literal strings
# "True"/"False" though, so a column whose every observed (present,
# non-blank) value is one of those two is a boolean in disguise.
$boolean = New-Object System.Collections.Generic.HashSet[string]
foreach ($c in $columns) {
    if ($numeric.Contains($c)) { continue }
    $observed = New-Object System.Collections.Generic.HashSet[string]
    $onlyTrueFalse = $true
    $anyObserved = $false
    foreach ($r in $flat.Rows) {
        if ($r.Contains($c) -and $r[$c] -ne $null -and $r[$c] -ne '') {
            $anyObserved = $true
            if ($r[$c] -ne 'True' -and $r[$c] -ne 'False') { $onlyTrueFalse = $false; break }
        }
    }
    if ($anyObserved -and $onlyTrueFalse) { $boolean.Add($c) | Out-Null }
}

$types = [ordered]@{}
foreach ($c in $columns) {
    $types[$c] = $(if ($numeric.Contains($c)) { 'Double' } elseif ($boolean.Contains($c)) { 'Boolean' } else { 'String' })
}

# --- meta ----------------------------------------------------------------
$xdoc = [System.Xml.Linq.XDocument]::Load($XmlPath)
$req = $xdoc.Root.Element('BCReportInformation')
if ($req) { $req = $req.Element('ReportRequest') }
$meta = [ordered]@{}
foreach ($k in @('CompanyName', 'UserName', 'Language', 'FormatRegion', 'DateAndTime')) {
    $meta[$k] = $(if ($req) { $el = $req.Element($k); if ($el) { $el.Value } else { '' } } else { '' })
}

# --- dataset.json ----------------------------------------------------------
# JSON is the machine-readable artefact: it preserves the distinction between
# "column absent on this row" ($null -> DBNull in the renderer) and "column
# present but blank" (""). Padding to the full column list happens HERE, not
# during flattening -- a row's hashtable only has keys bcdataset.ps1 actually
# saw, exactly like bcdataset.py's partial dicts.
$outRows = New-Object System.Collections.Generic.List[object]
foreach ($r in $flat.Rows) {
    $padded = [ordered]@{}
    foreach ($c in $columns) {
        $padded[$c] = $(if ($r.Contains($c)) { $r[$c] } else { $null })
    }
    $outRows.Add($padded) | Out-Null
}

$datasetOut = [ordered]@{
    dataSetName = $datasetName
    meta        = $meta
    columns     = $columns
    types       = $types
    rows        = $outRows
}
# Explicit -Depth, well above the real nesting (root -> rows -> row ->
# scalar): the PS 5.1 default of 2 would flatten `rows` to `System.Object[]`
# strings instead of real JSON arrays/objects.
$json = ConvertTo-Json $datasetOut -Depth 10
$jsonPath = Join-Path $OutDir 'dataset.json'
[System.IO.File]::WriteAllText($jsonPath, $json, $utf8NoBom)

# --- dataset.csv -----------------------------------------------------------
# For eyeballing and for diffing against BC's own Excel export, which writes
# the literal string NULL for absent columns. Hand-rolled, not Export-Csv --
# its quoting/header conventions differ from what the flattener test expects.
function ConvertTo-CsvField([string]$value) {
    if ($value -match '[,"\r\n]') {
        return '"' + ($value -replace '"', '""') + '"'
    }
    return $value
}

$csvLines = New-Object System.Collections.Generic.List[string]
$csvLines.Add(($columns | ForEach-Object { ConvertTo-CsvField $_ }) -join ',')
foreach ($r in $flat.Rows) {
    $fields = foreach ($c in $columns) {
        if ($r.Contains($c)) { ConvertTo-CsvField ([string]$r[$c]) } else { 'NULL' }
    }
    $csvLines.Add(($fields -join ','))
}
$csvPath = Join-Path $OutDir 'dataset.csv'
$csvText = ($csvLines -join "`r`n") + "`r`n"
[System.IO.File]::WriteAllText($csvPath, $csvText, $utf8NoBom)

Write-Host "wrote $($flat.Rows.Count) rows x $($columns.Count) cols -> $jsonPath, $csvPath"
