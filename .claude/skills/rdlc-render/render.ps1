<#
.SYNOPSIS
  One turn of the loop: dataset + layout -> PDF -> per-page PNGs -> diff vs baseline.
  Pure PowerShell -- no Python anywhere in this path.

.DESCRIPTION
  First call for a given -Out dir captures a baseline (the render "as of
  now"); every later call rasterises the new render and diffs it against
  that baseline, reporting a per-page changed-pixel count into <Out>/diff/.
  The baseline is NOT overwritten automatically -- run accept-baseline.ps1
  once a change is confirmed correct, so the next edit diffs against the new
  state instead of the original one.

  Always renders PDF, not BcRender.cs's --format PNG mode: PNG mode uses
  ReportViewer's Image renderer, which was tried as the direct-to-PNG default
  and rejected -- it measures text differently from ReportViewer's PDF
  renderer, enough to change actual pagination on this repo's own fixture
  (2 pages as PDF, 3 as direct PNG, with a column wrapping mid-value). PDF
  output is rasterised here with Rasterize-BcPdf.ps1 (WinRT
  Windows.Data.Pdf, built into Windows, no install), and diffed with
  diff.ps1 (System.Drawing LockBits, not GetPixel). See CLAUDE.md's Fidelity
  section before reaching for --format PNG.

.PARAMETER Rdl
  Path to the .rdlc layout under test.

.PARAMETER Xml
  Path to the dataset XML (BC's Send to > XML Document export).

.PARAMETER Out
  Output directory. Default: render

.EXAMPLE
  .\render.ps1 fixtures\report-106\CustomerDetailedAging.rdlc fixtures\report-106\Customer_Detailed_Aging.xml
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)] [string]$Rdl,
    [Parameter(Mandatory = $true, Position = 1)] [string]$Xml,
    [Parameter(Position = 2)] [string]$Out = 'render'
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'Rasterize-BcPdf.ps1')

$Exe = Join-Path $ScriptDir 'lib\bcrender.exe'
if (-not (Test-Path $Exe)) {
    Write-Host "lib\bcrender.exe not found -- running bootstrap.ps1 first ..."
    & (Join-Path $ScriptDir 'bootstrap.ps1')
    if (-not (Test-Path $Exe)) { throw "bootstrap.ps1 ran but lib\bcrender.exe still doesn't exist -- see its output above" }
}

& (Join-Path $ScriptDir 'bcdataset.ps1') $Xml $Rdl -OutDir $Out
# No $LASTEXITCODE check here or after other .ps1 calls below -- invoking a
# script with & doesn't reliably set it (only a native .exe call does), and
# $ErrorActionPreference = 'Stop' already turns a real failure inside
# bcdataset.ps1 into a terminating error that propagates out of this &
# automatically. A stale $LASTEXITCODE from some earlier native call would
# make this check fire on a run that actually succeeded.
& $Exe --rdl $Rdl --data (Join-Path $Out 'dataset.json') `
       --params (Join-Path $Out 'parameters.json') --out (Join-Path $Out 'report.pdf') --format PDF
if ($LASTEXITCODE -ne 0) { throw "bcrender.exe failed" }

Rasterize-BcPdf -PdfPath (Join-Path $Out 'report.pdf') -OutDir (Join-Path $Out 'pages') -Dpi 110 | Out-Null

$baselineDir = Join-Path $Out 'baseline'
if (Test-Path $baselineDir) {
    Write-Host "--- pixel diff vs baseline (run accept-baseline.ps1 to promote this render) ---"
    & (Join-Path $ScriptDir 'diff.ps1') $baselineDir (Join-Path $Out 'pages') -Out (Join-Path $Out 'diff')
}
else {
    New-Item -ItemType Directory -Force -Path $baselineDir | Out-Null
    Copy-Item (Join-Path $Out 'pages\page-*.png') $baselineDir
    $n = (Get-ChildItem $baselineDir -Filter 'page-*.png').Count
    Write-Host "baseline captured ($n pages) -- this is the reference future runs diff against"
}
