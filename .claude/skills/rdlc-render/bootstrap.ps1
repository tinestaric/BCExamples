<#
.SYNOPSIS
  One-time (per machine) setup for the PowerShell RDLC render loop.

.DESCRIPTION
  Populates lib/ with Microsoft's own ReportViewer 15 assemblies (WebForms
  flavor -- what BC on-prem ships) and Microsoft.SqlServer.Types, then
  compiles lib/bcrender.exe from BcRender.cs using the .NET Framework
  compiler that ships with Windows (csc.exe). No .NET SDK, no NuGet client,
  no build tooling beyond what Windows already has.

  Windows PowerShell 5.1 only. PS 7.x is .NET Core/5+ and cannot load these
  .NET Framework assemblies -- ReportViewer ends up unable to find its own
  expression-host assembly in the sandbox AppDomain PS7 spins up. If you're
  on PS7, Linux, or CI, use harness/ (dotnet run) instead; this script exists
  because that path costs a ~106 MB self-contained publish and a .NET 8 SDK
  that most consumers don't otherwise need.

.PARAMETER LibDir
  Use an existing directory of ReportViewer + SqlServer.Types DLLs instead of
  downloading from nuget.org (e.g. if nuget.org is blocked from this
  machine). Must contain, flat, at minimum: Microsoft.ReportViewer.Common.dll,
  Microsoft.ReportViewer.WebForms.dll, Microsoft.ReportViewer.ProcessingObjectModel.dll,
  Microsoft.ReportViewer.DataVisualization.dll, Microsoft.SqlServer.Types.dll,
  and its native companion SqlServerSpatial140.dll (+ msvcr120.dll). A BC
  on-prem install's Service/ folder plus Service/SideServices/ and
  Service/SideServices/x64/ has all of these, just not flattened into one
  directory -- copy them together first.

.PARAMETER Force
  Recompile bcrender.exe even if it already exists.

.EXAMPLE
  .\bootstrap.ps1
  .\bootstrap.ps1 -LibDir 'C:\Program Files\Microsoft Dynamics 365 Business Central\260\Service\_flattened'
#>
[CmdletBinding()]
param(
    [string]$LibDir,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Lib = Join-Path $ScriptDir 'lib'

if ($PSVersionTable.PSVersion.Major -ne 5) {
    Write-Error @"
This script requires Windows PowerShell 5.1 (found $($PSVersionTable.PSVersion)).
PS 7.x is .NET Core/5+ and cannot load the .NET Framework ReportViewer
assemblies this loop depends on -- rendering fails with 'Failed to load
expression host assembly' because PS7's sandbox AppDomain can't see them.

Run this from Windows PowerShell (powershell.exe), not pwsh.exe.
If you're not on Windows at all, use harness/ (dotnet run --project harness)
instead -- it needs the .NET 8 SDK but works cross-platform.
"@
}

New-Item -ItemType Directory -Force -Path $Lib | Out-Null

# Pin exact versions. The ReportViewer package version below is assembly
# version 15.0.1620.0, matching what BC 26 on-prem ships byte-for-byte --
# confirmed by rendering the same fixture with both and diffing the PDFs
# (identical, modulo the timestamp/user header). The SqlServer.Types version
# is the one ReportViewer's own dependency chain expects (14.0.x); pulling a
# newer one (e.g. 16.0.x, which BC itself ships) hits an assembly-identity
# mismatch at render time.
$ReportViewerPkg = 'microsoft.reportingservices.reportviewercontrol.webforms'
$ReportViewerVer = '150.1620.0'
$SqlTypesPkg = 'microsoft.sqlserver.types'
$SqlTypesVer = '14.0.314.76'

$NeededFiles = @(
    'Microsoft.ReportViewer.Common.dll',
    'Microsoft.ReportViewer.WebForms.dll',
    'Microsoft.ReportViewer.ProcessingObjectModel.dll',
    'Microsoft.ReportViewer.DataVisualization.dll',
    'Microsoft.SqlServer.Types.dll',
    'SqlServerSpatial140.dll',
    'msvcr120.dll'
)

$haveAll = $true
foreach ($f in $NeededFiles) { if (-not (Test-Path (Join-Path $Lib $f))) { $haveAll = $false } }

if ($haveAll -and -not $Force) {
    Write-Host "lib/ already populated ($($NeededFiles.Count) files) -- skipping fetch. Use -Force to redo."
}
elseif ($LibDir) {
    Write-Host "Copying ReportViewer assemblies from -LibDir: $LibDir"
    foreach ($f in $NeededFiles) {
        $src = Join-Path $LibDir $f
        if (-not (Test-Path $src)) { throw "-LibDir is missing required file: $f (looked in $LibDir)" }
        Copy-Item $src (Join-Path $Lib $f) -Force
    }
}
else {
    Write-Host "Downloading Microsoft's official ReportViewer + SqlServer.Types packages from nuget.org..."
    # Stock PS 5.1 often defaults to SSL3/TLS1.0, which nuget.org rejects.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $work = Join-Path $env:TEMP ("bcrender-nuget-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    try {
        function Get-NugetPackage($id, $ver) {
            $zip = Join-Path $work "$id.zip"
            $url = "https://api.nuget.org/v3-flatcontainer/$id/$ver/$id.$ver.nupkg"
            Write-Host "  GET $url"
            Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -TimeoutSec 120
            $dest = Join-Path $work $id
            Expand-Archive -Path $zip -DestinationPath $dest -Force
            return $dest
        }

        $rvDir = Get-NugetPackage $ReportViewerPkg $ReportViewerVer
        $stDir = Get-NugetPackage $SqlTypesPkg $SqlTypesVer

        $rvLib = Join-Path $rvDir 'lib\net40'
        foreach ($n in 'Microsoft.ReportViewer.Common', 'Microsoft.ReportViewer.WebForms',
                        'Microsoft.ReportViewer.ProcessingObjectModel', 'Microsoft.ReportViewer.DataVisualization') {
            Copy-Item (Join-Path $rvLib "$n.dll") $Lib -Force
        }
        Copy-Item (Join-Path $stDir 'lib\net40\Microsoft.SqlServer.Types.dll') $Lib -Force
        Copy-Item (Join-Path $stDir 'nativeBinaries\x64\SqlServerSpatial140.dll') $Lib -Force
        Copy-Item (Join-Path $stDir 'nativeBinaries\x64\msvcr120.dll') $Lib -Force
    }
    finally {
        Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$total = (Get-ChildItem $Lib -File | Measure-Object Length -Sum).Sum
Write-Host ("lib/ populated: {0} files, {1:N1} MB" -f (Get-ChildItem $Lib -File).Count, ($total / 1MB))

# --- Compile bcrender.exe with the in-box .NET Framework compiler ----------
$ExePath = Join-Path $Lib 'bcrender.exe'
$SrcPath = Join-Path $ScriptDir 'BcRender.cs'

if ((Test-Path $ExePath) -and -not $Force) {
    Write-Host "lib\bcrender.exe already present -- skipping compile. Use -Force to recompile."
}
else {
    $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    if (-not (Test-Path $csc)) {
        # 32-bit PowerShell on a 64-bit OS, or an unusual .NET Framework layout.
        $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
    }
    if (-not (Test-Path $csc)) {
        throw "Could not find csc.exe (.NET Framework 4 compiler) under $env:WINDIR\Microsoft.NET. " +
              "This ships with every Windows install that has .NET Framework 4 -- if it's truly missing, " +
              "enable the '.NET Framework 4.x' Windows feature."
    }

    Write-Host "Compiling bcrender.exe with $csc ..."
    $cscArgs = @(
        '/nologo',
        '/target:exe',
        '/platform:x64',
        "/out:$ExePath",
        "/r:$(Join-Path $Lib 'Microsoft.ReportViewer.WebForms.dll')",
        "/r:$(Join-Path $Lib 'Microsoft.ReportViewer.Common.dll')",
        '/r:System.Data.dll',
        '/r:System.Xml.dll',
        '/r:System.Web.dll',
        '/r:System.Web.Extensions.dll',
        $SrcPath
    )
    & $csc $cscArgs
    if ($LASTEXITCODE -ne 0) { throw "csc.exe failed with exit code $LASTEXITCODE" }
    if (-not (Test-Path $ExePath)) { throw "csc.exe reported success but $ExePath was not created" }
    Write-Host "compiled: $ExePath"
}

# --- Self-verify: render the reference fixture ------------------------------
$fixtureRdl = Join-Path $ScriptDir 'fixtures\report-106\CustomerDetailedAging.rdlc'
$fixtureData = Join-Path $ScriptDir 'fixtures\report-106\expected-flattened\dataset.json'
$fixtureParams = Join-Path $ScriptDir 'fixtures\report-106\expected-flattened\parameters.json'
if ((Test-Path $fixtureRdl) -and (Test-Path $fixtureData)) {
    Write-Host "Self-verifying against fixtures/report-106 ..."
    $tmpOut = Join-Path $env:TEMP ("bcrender-selftest-" + [Guid]::NewGuid().ToString('N') + '.pdf')
    & $ExePath --rdl $fixtureRdl --data $fixtureData --params $fixtureParams --out $tmpOut
    if ($LASTEXITCODE -ne 0) { throw "bcrender.exe self-test failed (exit $LASTEXITCODE) -- see output above" }
    $sz = (Get-Item $tmpOut).Length
    Remove-Item $tmpOut -Force -ErrorAction SilentlyContinue
    Write-Host "self-test OK: rendered $sz bytes"
}

Write-Host ""
Write-Host "bootstrap complete. Run render.ps1 to render a layout."
