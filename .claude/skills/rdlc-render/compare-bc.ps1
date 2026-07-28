<#
.SYNOPSIS
  Conformance check: diff the current render against a PDF BC itself produced
  for the same report/dataset/filter. Independent of the running baseline in
  render.ps1 -- this is "how far from production", not "what did my edit do".
  Pure PowerShell -- no Python anywhere in this path.

.EXAMPLE
  .\compare-bc.ps1 render fixtures\report-106\bc-reference.pdf
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)] [string]$Out,
    [Parameter(Mandatory = $true, Position = 1)] [string]$BcPdf
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'Rasterize-BcPdf.ps1')

$pagesDir = Join-Path $Out 'pages'
if (-not (Test-Path $pagesDir)) { throw "no $pagesDir -- run render.ps1 first" }

$bcPagesDir = Join-Path $Out 'bc-pages'
Rasterize-BcPdf -PdfPath $BcPdf -OutDir $bcPagesDir -Dpi 110 | Out-Null

Write-Host "--- conformance diff: our render vs $BcPdf ---"
& (Join-Path $ScriptDir 'diff.ps1') $bcPagesDir $pagesDir -Out (Join-Path $Out 'conformance-diff')
