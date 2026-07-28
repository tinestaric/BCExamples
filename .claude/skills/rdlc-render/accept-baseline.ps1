<#
.SYNOPSIS
  Promote the current render as the new baseline for a given -Out dir, once a
  layout edit's diff has been reviewed and confirmed correct. Without this,
  render.ps1 keeps diffing against whatever render came first.

.EXAMPLE
  .\accept-baseline.ps1 render
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)] [string]$Out = 'render'
)

$ErrorActionPreference = 'Stop'
$pagesDir = Join-Path $Out 'pages'
if (-not (Test-Path $pagesDir)) { throw "no $pagesDir -- run render.ps1 first" }

$baselineDir = Join-Path $Out 'baseline'
if (Test-Path $baselineDir) { Remove-Item $baselineDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $baselineDir | Out-Null
Copy-Item (Join-Path $pagesDir 'page-*.png') $baselineDir

$n = (Get-ChildItem $baselineDir -Filter 'page-*.png').Count
Write-Host "baseline promoted from $pagesDir ($n pages)"
